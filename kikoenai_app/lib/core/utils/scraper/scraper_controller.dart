import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

typedef ScraperWorkLoader =
    Future<Work> Function(
      int workId,
      ScraperCancellationToken cancellationToken,
    );
typedef ScraperWorkExists = bool Function(int workId);
typedef ScraperWorkSaver = Future<void> Function(int workId, Work work);
typedef ScraperStatusUpdater =
    Future<void> Function(int workId, NodeStatus status);

final scraperWorkLoaderProvider = Provider<ScraperWorkLoader>((ref) {
  return (workId, cancellationToken) async {
    final rawData = await DlSiteScraper.scrapeAll(
      workId,
      cancellationToken: cancellationToken,
    );
    return Work.fromJson(rawData);
  };
});

final scraperWorkExistsProvider = Provider<ScraperWorkExists>((ref) {
  return ScraperStorage().hasWork;
});

final scraperWorkSaverProvider = Provider<ScraperWorkSaver>((ref) {
  return ScraperStorage().saveWork;
});

final scraperStatusUpdaterProvider = Provider<ScraperStatusUpdater>((ref) {
  return (workId, status) async {
    await FileScannerStorage().updateNodeStatusByWorkIdGlobally(workId, status);
    FileScannerService.instance.updateWorkStatusInCurrentResult(
      workId: workId,
      status: status,
    );
  };
});

final scraperQueueDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

final scraperQueueConcurrencyProvider = Provider<int>((ref) => 2);

@immutable
class ScraperQueueState {
  final List<FileNode> pending; // 等待爬取的队列
  final List<FileNode> processing; // 正在爬取的任务（受并发数量控制，包含 parsing 状态的节点）
  final List<FileNode> paused; // 已暂停，可单独或批量继续
  final List<FileNode> completed; // 本次运行期间爬取成功的任务 (parsed)
  final List<FileNode> failed; // 爬取失败的任务
  final bool isRunning; // 是否处于运行状态（用于控制开始/暂停）

  const ScraperQueueState({
    this.pending = const [],
    this.processing = const [],
    this.paused = const [],
    this.completed = const [],
    this.failed = const [],
    this.isRunning = false, // 默认不运行，等待用户手动点击开始
  });

  ScraperQueueState copyWith({
    List<FileNode>? pending,
    List<FileNode>? processing,
    List<FileNode>? paused,
    List<FileNode>? completed,
    List<FileNode>? failed,
    bool? isRunning,
  }) {
    return ScraperQueueState(
      pending: pending ?? this.pending,
      processing: processing ?? this.processing,
      paused: paused ?? this.paused,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// 快捷属性：是否所有任务都已结束
  bool get isIdle => pending.isEmpty && processing.isEmpty && paused.isEmpty;

  bool get canStart => !isRunning && (pending.isNotEmpty || paused.isNotEmpty);

  bool get canPause =>
      isRunning && (pending.isNotEmpty || processing.isNotEmpty);

  /// 快捷属性：当前队列的总进度 (0.0 ~ 1.0)
  double get progress {
    final total =
        pending.length +
        processing.length +
        paused.length +
        completed.length +
        failed.length;
    if (total == 0) return 0.0;
    return (completed.length + failed.length) / total;
  }
}

class ScraperQueueNotifier extends Notifier<ScraperQueueState> {
  final Map<String, ScraperCancellationToken> _cancellationTokens = {};
  final Set<String> _activeTaskIds = {};
  final Set<String> _pauseRequested = {};
  final Set<String> _discardRequested = {};

  @override
  ScraperQueueState build() {
    return const ScraperQueueState();
  }

  /// 外部接口：由弹窗“确认加入队列”后调用，提交新任务
  Future<void> addTasks(List<FileNode> nodes) async {
    // 过滤掉无效节点或已经在内存队列中的节点
    final validNodes = nodes.where((n) {
      if (n.workId == null) return false;
      final inQueue =
          state.pending.any((p) => p.keyId == n.keyId) ||
          state.processing.any((p) => p.keyId == n.keyId) ||
          state.paused.any((p) => p.keyId == n.keyId);
      return !inQueue;
    }).toList();

    if (validNodes.isEmpty) return;

    // 因为取消了 queued 状态，节点原本就是 pending，不需要再写入数据库修改状态
    state = state.copyWith(pending: [...state.pending, ...validNodes]);

    // 如果当前处于运行状态，则直接开始消费
    if (state.isRunning) {
      _pumpQueue();
    }
  }

  // ================= 手动控制 API =================

  /// 开始/继续解析
  void start() {
    if (state.isRunning) return;
    final resumed = _appendUnique(state.pending, state.paused);
    if (resumed.isEmpty) return;

    for (final node in state.paused) {
      if (!_activeTaskIds.contains(node.keyId)) {
        _pauseRequested.remove(node.keyId);
      }
    }
    state = state.copyWith(pending: resumed, paused: const [], isRunning: true);
    _pumpQueue();
  }

  /// 暂停所有排队和执行中的任务，并取消正在进行的网络请求。
  void pauseAll() {
    final tasksToPause = [...state.pending, ...state.processing];
    if (tasksToPause.isEmpty) {
      if (state.isRunning) state = state.copyWith(isRunning: false);
      return;
    }

    _pauseRequested.addAll(tasksToPause.map((node) => node.keyId));
    state = state.copyWith(
      pending: const [],
      processing: const [],
      paused: _appendUnique(state.paused, tasksToPause),
      isRunning: false,
    );
    for (final node in tasksToPause) {
      _cancellationTokens[node.keyId]?.cancel('全部任务已暂停');
      _persistPendingStatus(node);
    }
  }

  /// 兼容原调用；现在会真正取消所有进行中的任务。
  void pause() => pauseAll();

  void pauseTask(String taskId) {
    final node = _findTask(taskId, [...state.pending, ...state.processing]);
    if (node == null) return;

    _pauseRequested.add(taskId);
    final pending = state.pending
        .where((item) => item.keyId != taskId)
        .toList();
    final processing = state.processing
        .where((item) => item.keyId != taskId)
        .toList();
    final stillRunning =
        state.isRunning && (pending.isNotEmpty || processing.isNotEmpty);
    state = state.copyWith(
      pending: pending,
      processing: processing,
      paused: _appendUnique(state.paused, [node]),
      isRunning: stillRunning,
    );
    _cancellationTokens[taskId]?.cancel('任务已暂停');
    _persistPendingStatus(node);
    if (state.isRunning) _pumpQueue();
  }

  void resumeTask(String taskId) {
    final node = _findTask(taskId, state.paused);
    if (node == null) return;

    if (!_activeTaskIds.contains(taskId)) {
      _pauseRequested.remove(taskId);
    }
    state = state.copyWith(
      pending: _appendUnique(state.pending, [node]),
      paused: state.paused.where((item) => item.keyId != taskId).toList(),
      isRunning: true,
    );
    _pumpQueue();
  }

  void retryTask(String taskId) {
    final node = _findTask(taskId, state.failed);
    if (node == null) return;
    state = state.copyWith(
      pending: _appendUnique(state.pending, [node]),
      failed: state.failed.where((item) => item.keyId != taskId).toList(),
      isRunning: true,
    );
    _pumpQueue();
  }

  /// 打断排队并清空
  void clearQueue() {
    final queuedNodes = _appendUnique(const [], [
      ...state.pending,
      ...state.processing,
      ...state.paused,
    ]);
    final activeNodes = queuedNodes
        .where((node) => _activeTaskIds.contains(node.keyId))
        .toList();

    _pauseRequested.clear();
    _discardRequested
      ..clear()
      ..addAll(_activeTaskIds);
    state = const ScraperQueueState();

    for (final cancellationToken in _cancellationTokens.values) {
      cancellationToken.cancel('队列已清空');
    }
    for (final node in activeNodes) {
      _persistPendingStatus(node);
    }
  }

  // ================================================

  /// 内部循环引擎：驱动队列运转
  void _pumpQueue() {
    if (!state.isRunning) return;

    final maxConcurrency = ref.read(scraperQueueConcurrencyProvider);
    while (_activeTaskIds.length < maxConcurrency && state.pending.isNotEmpty) {
      final nextIndex = state.pending.indexWhere(
        (node) => !_activeTaskIds.contains(node.keyId),
      );
      if (nextIndex == -1) return;

      final nextNode = state.pending[nextIndex];
      final pending = List<FileNode>.from(state.pending)..removeAt(nextIndex);
      final cancellationToken = ScraperCancellationToken();
      _activeTaskIds.add(nextNode.keyId);
      _cancellationTokens[nextNode.keyId] = cancellationToken;
      state = state.copyWith(
        pending: pending,
        processing: _appendUnique(state.processing, [nextNode]),
      );
      unawaited(_runTask(nextNode, cancellationToken));
    }
  }

  Future<void> _runTask(
    FileNode node,
    ScraperCancellationToken cancellationToken,
  ) async {
    final parsingNode = node.copyWith(nodeStatus: NodeStatus.parsing);
    try {
      await cancellationToken.wait(ref.read(scraperQueueDelayProvider));
      cancellationToken.throwIfCancelled();

      final id = parsingNode.workId;
      if (id == null) return;
      await _updateWorkStatus(id, NodeStatus.parsing);
      cancellationToken.throwIfCancelled();

      if (!ref.read(scraperWorkExistsProvider)(id)) {
        debugPrint('[ScraperQueue] 开始爬取网络元数据: $id');
        final work = await ref.read(scraperWorkLoaderProvider)(
          id,
          cancellationToken,
        );
        cancellationToken.throwIfCancelled();
        await ref.read(scraperWorkSaverProvider)(id, work);
      } else {
        debugPrint('[ScraperQueue] 命中本地缓存，跳过网络爬取: $id');
      }
      cancellationToken.throwIfCancelled();

      final parsedNode = parsingNode.copyWith(nodeStatus: NodeStatus.parsed);
      await _updateWorkStatus(id, NodeStatus.parsed);
      cancellationToken.throwIfCancelled();

      state = state.copyWith(
        processing: state.processing
            .where((n) => n.keyId != parsingNode.keyId)
            .toList(),
        completed: _appendUnique(state.completed, [parsedNode]),
      );
    } on ScraperCancelledException {
      await _handleCancellation(node);
    } catch (e, stack) {
      if (cancellationToken.isCancelled) {
        await _handleCancellation(node);
        return;
      }

      debugPrint('[ScraperQueue] 爬取任务崩溃: $parsingNode \n异常: $e\n$stack');

      final failedNode = parsingNode.copyWith(nodeStatus: NodeStatus.pending);
      final id = failedNode.workId;
      if (id != null) {
        await _updateWorkStatus(id, NodeStatus.pending);
      }

      state = state.copyWith(
        processing: state.processing
            .where((n) => n.keyId != parsingNode.keyId)
            .toList(),
        failed: _appendUnique(state.failed, [failedNode]),
      );
    } finally {
      _activeTaskIds.remove(node.keyId);
      _pauseRequested.remove(node.keyId);
      _discardRequested.remove(node.keyId);
      if (identical(_cancellationTokens[node.keyId], cancellationToken)) {
        _cancellationTokens.remove(node.keyId);
      }
      if (state.isRunning && state.pending.isNotEmpty) {
        _pumpQueue();
      } else if (state.isRunning && _activeTaskIds.isEmpty) {
        state = state.copyWith(isRunning: false);
      }
    }
  }

  Future<void> _handleCancellation(FileNode node) async {
    final taskId = node.keyId;
    final shouldDiscard = _discardRequested.remove(taskId);
    final shouldPause = _pauseRequested.remove(taskId);
    final pending = state.pending.any((item) => item.keyId == taskId);

    state = state.copyWith(
      processing: state.processing
          .where((item) => item.keyId != taskId)
          .toList(),
      paused: shouldDiscard || pending || !shouldPause
          ? state.paused.where((item) => item.keyId != taskId).toList()
          : _appendUnique(state.paused, [node]),
    );
    if (node.workId != null) {
      await _updateWorkStatus(node.workId!, NodeStatus.pending);
    }
  }

  Future<void> _updateWorkStatus(int workId, NodeStatus status) async {
    await ref.read(scraperStatusUpdaterProvider)(workId, status);
  }

  void _persistPendingStatus(FileNode node) {
    final workId = node.workId;
    if (workId == null) return;
    unawaited(
      _updateWorkStatus(workId, NodeStatus.pending).catchError((error, stack) {
        debugPrint('[ScraperQueue] 更新暂停状态失败: $error\n$stack');
      }),
    );
  }

  FileNode? _findTask(String taskId, Iterable<FileNode> tasks) {
    for (final task in tasks) {
      if (task.keyId == taskId) return task;
    }
    return null;
  }

  List<FileNode> _appendUnique(
    Iterable<FileNode> current,
    Iterable<FileNode> additions,
  ) {
    final result = <FileNode>[];
    final seen = <String>{};
    for (final node in [...current, ...additions]) {
      if (seen.add(node.keyId)) result.add(node);
    }
    return result;
  }
}

final scraperQueueProvider =
    NotifierProvider<ScraperQueueNotifier, ScraperQueueState>(() {
      return ScraperQueueNotifier();
    });
