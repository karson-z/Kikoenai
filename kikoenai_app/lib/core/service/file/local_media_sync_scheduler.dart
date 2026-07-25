import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/core/model/local_media/file_scanner_state.dart';
import 'package:kikoenai/features/local_media/data/repository/scanner_path_repository.dart';

import 'file_scan_sync_engine.dart';

enum LocalMediaSyncReason { startup, manual, newTarget, threshold }

class LocalMediaSyncJob {
  final ScanTarget target;
  final LocalMediaSyncReason reason;
  final int priority;
  final int cost;
  final int attempt;

  const LocalMediaSyncJob({
    required this.target,
    required this.reason,
    required this.priority,
    required this.cost,
    this.attempt = 0,
  });

  String get key => LocalMediaSyncScheduler.jobKey(target);
}

class LocalMediaSyncScheduler {
  LocalMediaSyncScheduler._();

  static final LocalMediaSyncScheduler instance = LocalMediaSyncScheduler._();

  final ScannerPathRepository _repository = ScannerPathRepository.instance;
  final FileScanSyncEngine _syncEngine = FileScanSyncEngine();
  final Queue<LocalMediaSyncJob> _queue = Queue<LocalMediaSyncJob>();
  final Set<String> _queuedKeys = {};
  final Set<String> _runningKeys = {};

  var _runningTokens = 0;
  var _paused = false;
  var _started = false;

  static String jobKey(ScanTarget target) {
    return '${target.scanMode.name}_${target.path.replaceAll('\\', '/').toLowerCase()}';
  }

  Future<void> runStartupCheck() async {
    if (_started) return;
    _started = true;

    if (!_autoSyncEnabled) return;

    final candidates = _collectStartupCandidates();
    if (candidates.isEmpty) return;

    for (final target in candidates) {
      enqueue(
        target,
        reason: target.lastScannedAt == null
            ? LocalMediaSyncReason.newTarget
            : LocalMediaSyncReason.threshold,
      );
    }
  }

  void enqueue(
    ScanTarget target, {
    LocalMediaSyncReason reason = LocalMediaSyncReason.manual,
  }) {
    final key = jobKey(target);
    if (_queuedKeys.contains(key) || _runningKeys.contains(key)) return;

    final job = LocalMediaSyncJob(
      target: target,
      reason: reason,
      priority: _priorityFor(target, reason),
      cost: _costFor(target).clamp(1, _maxTokens),
    );

    final jobs = [..._queue, job]
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;

        final aLast = a.target.lastScannedAt ?? 0;
        final bLast = b.target.lastScannedAt ?? 0;
        return aLast.compareTo(bLast);
      });

    _queue
      ..clear()
      ..addAll(jobs);
    _queuedKeys.add(key);
    _pump();
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
    _pump();
  }

  void dispose() {
    _paused = true;
    _queue.clear();
    _queuedKeys.clear();
  }

  List<ScanTarget> _collectStartupCandidates() {
    final activeTarget = _repository.getActiveTarget();
    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = Duration(hours: _thresholdHours.clamp(1, 168));

    final targets = _repository.getAllTargets().where((target) {
      if (!_pathExists(target.path)) return false;

      final lastScannedAt = target.lastScannedAt;
      if (lastScannedAt == null || lastScannedAt <= 0) return true;

      return now - lastScannedAt >= threshold.inMilliseconds;
    }).toList();

    targets.sort((a, b) {
      final aActive = _isSameTarget(a, activeTarget);
      final bActive = _isSameTarget(b, activeTarget);
      if (aActive != bActive) return aActive ? -1 : 1;

      final aNever = a.lastScannedAt == null || a.lastScannedAt == 0;
      final bNever = b.lastScannedAt == null || b.lastScannedAt == 0;
      if (aNever != bNever) return aNever ? -1 : 1;

      final byMode = _costFor(a).compareTo(_costFor(b));
      if (byMode != 0) return byMode;

      return (a.lastScannedAt ?? 0).compareTo(b.lastScannedAt ?? 0);
    });

    return targets;
  }

  void _pump() {
    if (_paused) return;

    while (_queue.isNotEmpty) {
      final job = _nextRunnableJob();
      if (job == null) return;

      _queue.remove(job);
      _queuedKeys.remove(job.key);
      _runningKeys.add(job.key);
      _runningTokens += job.cost;
      unawaited(_runJob(job));
    }
  }

  LocalMediaSyncJob? _nextRunnableJob() {
    final availableTokens = _maxTokens - _runningTokens;
    if (availableTokens <= 0) return null;

    for (final job in _queue) {
      if (job.cost <= availableTokens) return job;
    }
    return null;
  }

  Future<void> _runJob(LocalMediaSyncJob job) async {
    try {
      debugPrint(
        '[LocalMediaSyncScheduler] start ${job.target.scanMode.name}: ${job.target.path}',
      );

      await _syncEngine.syncTarget(target: job.target);
      await _repository.updateLastScannedAt(
        job.target.path,
        job.target.scanMode,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint(
        '[LocalMediaSyncScheduler] done ${job.target.scanMode.name}: ${job.target.path}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[LocalMediaSyncScheduler] failed ${job.target.scanMode.name}: ${job.target.path}\n$e\n$stackTrace',
      );
    } finally {
      _runningTokens -= job.cost;
      if (_runningTokens < 0) {
        _runningTokens = 0;
      }
      _runningKeys.remove(job.key);
      _pump();
    }
  }

  int _priorityFor(ScanTarget target, LocalMediaSyncReason reason) {
    final activeTarget = _repository.getActiveTarget();
    var priority = 0;

    if (_isSameTarget(target, activeTarget)) {
      priority += 1000;
    }
    if (target.lastScannedAt == null || target.lastScannedAt == 0) {
      priority += 500;
    }

    priority += switch (reason) {
      LocalMediaSyncReason.manual => 400,
      LocalMediaSyncReason.newTarget => 300,
      LocalMediaSyncReason.startup => 200,
      LocalMediaSyncReason.threshold => 100,
    };

    priority -= _costFor(target) * 10;
    return priority;
  }

  int _costFor(ScanTarget target) {
    return target.scanMode.name == 'subtitles' ? 2 : 1;
  }

  bool _pathExists(String path) {
    return Directory(path).existsSync() || File(path).existsSync();
  }

  bool _isSameTarget(ScanTarget target, ScanTarget? other) {
    if (other == null) return false;
    return jobKey(target) == jobKey(other);
  }

  bool get _autoSyncEnabled {
    return AppStorage.settingsBox.get(
          StorageKeys.localMediaAutoSyncEnabled,
          defaultValue: true,
        )
        as bool;
  }

  int get _thresholdHours {
    return AppStorage.settingsBox.get(
          StorageKeys.localMediaAutoSyncThresholdHours,
          defaultValue: 24,
        )
        as int;
  }

  int get _maxTokens {
    final cores = Platform.numberOfProcessors;

    if (Platform.isAndroid || Platform.isIOS) {
      if (cores <= 4) return 1;
      if (cores <= 8) return 2;
      return 3;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return (cores ~/ 2).clamp(1, 4);
    }

    return 1;
  }
}
