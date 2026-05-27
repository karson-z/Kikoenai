import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/utils/scraper/scraper.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import '../../../../core/service/file/file_scanner_storage.dart';
import '../../service/file/file_scanner_service.dart';

@immutable
class ScraperQueueState {
  final List<FileNode> pending;    // 等待爬取的队列
  final List<FileNode> processing; // 正在爬取的任务（受并发数量控制，包含 parsing 状态的节点）
  final List<FileNode> completed;  // 本次运行期间爬取成功的任务 (parsed)
  final List<FileNode> failed;     // 爬取失败的任务
  final bool isRunning;            // 是否处于运行状态（用于控制开始/暂停）

  const ScraperQueueState({
    this.pending = const [],
    this.processing = const [],
    this.completed = const [],
    this.failed = const [],
    this.isRunning = false,        // 默认不运行，等待用户手动点击开始
  });

  ScraperQueueState copyWith({
    List<FileNode>? pending,
    List<FileNode>? processing,
    List<FileNode>? completed,
    List<FileNode>? failed,
    bool? isRunning,
  }) {
    return ScraperQueueState(
      pending: pending ?? this.pending,
      processing: processing ?? this.processing,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// 快捷属性：是否所有任务都已结束
  bool get isIdle => pending.isEmpty && processing.isEmpty;

  /// 快捷属性：当前队列的总进度 (0.0 ~ 1.0)
  double get progress {
    final total = pending.length + processing.length + completed.length + failed.length;
    if (total == 0) return 0.0;
    return (completed.length + failed.length) / total;
  }
}

class ScraperQueueNotifier extends Notifier<ScraperQueueState> {
  // --- 爬虫控制参数 ---
  final int maxConcurrency = 2; // 最大并发数，防止被封禁
  final Duration delayBetweenTasks = const Duration(seconds: 3); // 任务间的礼貌延迟

  @override
  ScraperQueueState build() {
    return const ScraperQueueState();
  }

  /// 外部接口：由弹窗“确认加入队列”后调用，提交新任务
  Future<void> addTasks(List<FileNode> nodes) async {
    // 过滤掉无效节点或已经在内存队列中的节点
    final validNodes = nodes.where((n) {
      if (n.workId == null) return false;
      final inQueue = state.pending.any((p) => p.keyId == n.keyId) ||
          state.processing.any((p) => p.keyId == n.keyId);
      return !inQueue;
    }).toList();

    if (validNodes.isEmpty) return;

    // 因为取消了 queued 状态，节点原本就是 pending，不需要再写入数据库修改状态
    state = state.copyWith(
      pending: [...state.pending, ...validNodes],
    );

    // 如果当前处于运行状态，则直接开始消费
    if (state.isRunning) {
      _pumpQueue();
    }
  }

  // ================= 手动控制 API =================

  /// 开始/继续解析
  void start() {
    if (state.isRunning || state.pending.isEmpty) return;
    state = state.copyWith(isRunning: true);
    _pumpQueue();
  }

  /// 暂停解析
  void pause() {
    if (!state.isRunning) return;
    state = state.copyWith(isRunning: false);
  }

  /// 打断排队并清空
  void clearQueue() {
    state = ScraperQueueState(
      processing: state.processing, // 保留正在执行的，等其自行消亡
      isRunning: false,             // 强制暂停
    );
  }

  // ================================================

  /// 内部循环引擎：驱动队列运转
  Future<void> _pumpQueue() async {
    if (!state.isRunning) return;

    // 并发熔断：正在处理的数量达到上限，或者队列已空
    if (state.processing.length >= maxConcurrency || state.pending.isEmpty) {
      return;
    }

    // 1. 出队
    final nextNode = state.pending.first;

    // 2. 状态转移：pending -> processing
    state = state.copyWith(
      pending: state.pending.sublist(1),
      processing: [...state.processing, nextNode],
    );

    // 3. 递归：只要并发额度有空余，立刻启动下一个任务
    _pumpQueue();

    // 4. 防封禁阻断：发起真实网络请求前的强制等待
    await Future.delayed(delayBetweenTasks);

    // 5. 执行工作单元
    await _executeScrape(nextNode);
  }

  /// 内部工作单元：执行单个解析和持久化任务
  /// 内部工作单元：执行单个解析和持久化任务
  Future<void> _executeScrape(FileNode node) async {
    // 1. 开始解析前，将队列中的节点状态更新，并通过全局静态方法落盘
    final parsingNode = node.copyWith(nodeStatus: NodeStatus.parsing);
    try {
      final id = parsingNode.workId;
      if (id == null) return;
      await _updateWorkStatus(id, NodeStatus.parsing);

      if (!ScraperStorage().hasWork(id)) {
        debugPrint('[ScraperQueue] 开始爬取网络元数据: $id');
        final rawData = await DlSiteScraper.scrapeAll(id);
        final work = Work.fromJson(rawData);
        await ScraperStorage().saveWork(id, work);
      } else {
        debugPrint('[ScraperQueue] 命中本地缓存，跳过网络爬取: $id');
      }
      // 2. 解析成功，全局同步 physical 状态为 parsed
      final parsedNode = parsingNode.copyWith(nodeStatus: NodeStatus.parsed);
      await _updateWorkStatus(id, NodeStatus.parsed);

      // 任务成功，状态转移 (内存队列中直接替换)
      state = state.copyWith(
        processing: state.processing.where((n) => n.keyId != parsingNode.keyId).toList(),
        completed: [...state.completed, parsedNode],
      );

    } catch (e, stack) {
      debugPrint('[ScraperQueue] 爬取任务崩溃: $parsingNode \n异常: $e\n$stack');

      // 3. 解析失败，全局同步 physical 状态退回 pending
      final failedNode = parsingNode.copyWith(nodeStatus: NodeStatus.pending);
      final id = failedNode.workId;
      if (id != null) {
        await _updateWorkStatus(id, NodeStatus.pending);
      }

      // 任务失败，状态转移
      state = state.copyWith(
        processing: state.processing.where((n) => n.keyId != parsingNode.keyId).toList(),
        failed: [...state.failed, failedNode],
      );
    } finally {
      if (state.isRunning) {
        _pumpQueue();
      }
    }
  }

  Future<void> _updateWorkStatus(int workId, NodeStatus status) async {
    await FileScannerStorage().updateNodeStatusByWorkIdGlobally(workId, status);
    FileScannerService.instance.updateWorkStatusInCurrentResult(
      workId: workId,
      status: status,
    );
  }
}

final scraperQueueProvider = NotifierProvider<ScraperQueueNotifier, ScraperQueueState>(() {
  return ScraperQueueNotifier();
});
