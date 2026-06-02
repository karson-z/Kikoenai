import 'dart:async';

import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/local_media/data/model/file_scanner_state.dart';

import '../../storage/hive_key.dart';
import '../../storage/hive_storage.dart';
import 'file_scan_sync_engine.dart';
import 'file_scanner_storage.dart';

export 'scan_mode.dart';

enum FileScannerResultPhase {
  cacheLoaded,
  syncSkipped,
  syncCompleted,
  statusUpdated,
}

class FileScannerResult {
  final List<FileNode> flatNodes;
  final int scannedCount;
  final String rootPath;
  final FileScannerResultPhase phase;

  const FileScannerResult({
    required this.flatNodes,
    required this.scannedCount,
    required this.rootPath,
    required this.phase,
  });
}

class FileScannerService {
  FileScannerService._();

  static final FileScannerService instance = FileScannerService._();

  final FileScanSyncEngine _syncEngine = FileScanSyncEngine();

  final FileScannerStorage _storage = FileScannerStorage();

  final StreamController<FileScannerResult> _resultController =
      StreamController<FileScannerResult>.broadcast();

  final List<FileNode> _flatFiles = [];

  Stream<FileScannerResult> get result => _resultController.stream;

  void dispose() {
    if (!_resultController.isClosed) {
      _resultController.close();
    }
  }

  Future<bool> startScan(
    ScanTarget scanTarget, {
    bool forceSync = false,
  }) async {
    final hasCache = await _initAndLoadCache(scanTarget);
    final shouldSync =
        forceSync || _shouldSilentSync(scanTarget, hasCache: hasCache);

    _emitCurrentResult(
      scanTarget.path,
      phase: shouldSync
          ? FileScannerResultPhase.cacheLoaded
          : FileScannerResultPhase.syncSkipped,
    );

    if (!shouldSync) return false;
    await _performSilentSync(scanTarget);
    return true;
  }

  void updateWorkStatusInCurrentResult({
    required int workId,
    required NodeStatus status,
  }) {
    var changed = false;

    for (var index = 0; index < _flatFiles.length; index++) {
      final node = _flatFiles[index];
      if (node.workId != workId || node.nodeStatus == status) continue;

      _flatFiles[index] = node.copyWith(nodeStatus: status);
      changed = true;
    }

    if (changed) {
      final rootPath = _flatFiles.firstOrNull?.rootPath ?? '';
      _emitStatusUpdatedResult(rootPath);
    }
  }

  /// 初始化并加载本地缓存
  Future<bool> _initAndLoadCache(ScanTarget scanTarget) async {
    _flatFiles
      ..clear()
      ..addAll(
        _storage
            .getNodesByRootPath(scanTarget.scanMode, scanTarget.path)
            .where((node) => !node.isFolder),
      );

    return _flatFiles.isNotEmpty;
  }

  bool _shouldSilentSync(ScanTarget scanTarget, {required bool hasCache}) {
    if (!hasCache) return true;

    final autoSyncEnabled =
        AppStorage.settingsBox.get(
              StorageKeys.localMediaAutoSyncEnabled,
              defaultValue: true,
            )
            as bool;
    if (!autoSyncEnabled) return false;

    final thresholdHours =
        AppStorage.settingsBox.get(
              StorageKeys.localMediaAutoSyncThresholdHours,
              defaultValue: 24,
            )
            as int;
    final threshold = Duration(hours: thresholdHours.clamp(1, 168));
    final lastScannedAt = scanTarget.lastScannedAt;

    if (lastScannedAt == null || lastScannedAt <= 0) return true;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastScannedAt;
    return elapsed >= threshold.inMilliseconds;
  }

  /// 静默同步磁盘
  Future<void> _performSilentSync(ScanTarget scanTarget) async {
    await _syncEngine.syncTarget(target: scanTarget, inMemoryNodes: _flatFiles);

    _emitCurrentResult(
      scanTarget.path,
      phase: FileScannerResultPhase.syncCompleted,
    );
  }

  void _emitStatusUpdatedResult(String rootPath) {
    _emitCurrentResult(rootPath, phase: FileScannerResultPhase.statusUpdated);
  }

  void _emitCurrentResult(
    String rootPath, {
    required FileScannerResultPhase phase,
  }) {
    _resultController.add(
      FileScannerResult(
        flatNodes: _flatFiles,
        scannedCount: _flatFiles.length,
        rootPath: rootPath,
        phase: phase,
      ),
    );
  }
}
