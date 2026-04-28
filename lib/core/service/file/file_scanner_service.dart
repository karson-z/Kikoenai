import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;
import '../../utils/scraper/scraper_storage.dart';
import 'file_scanner_storage.dart';
import 'file_scanner_worker.dart';
import 'file_tree_builder.dart';

enum ScanMode { audio, video, subtitles }

extension ScanModeConfig on ScanMode {
  Set<String> get extensions {
    switch (this) {
      case ScanMode.audio:
        return FileExtensions.audio;
      case ScanMode.video:
        return FileExtensions.video;
      case ScanMode.subtitles:
        return FileExtensions.subtitles;
    }
  }

  bool get scanArchives {
    switch (this) {
      case ScanMode.audio:
      case ScanMode.video:
        return false;
      case ScanMode.subtitles:
        return true;
    }
  }
}

enum SyncRunStatus {
  success,
  cancelled,
  error,
}

class CachedScanSnapshot {
  final List<FileNode> nodes;
  final RootScanMeta? meta;
  final int scannedCount;
  final bool hasCachedData;

  const CachedScanSnapshot({
    required this.nodes,
    required this.meta,
    required this.scannedCount,
    required this.hasCachedData,
  });
}

class SyncScanResult {
  final SyncRunStatus status;
  final String rootPath;
  final int runId;
  final int scannedCount;
  final String? errorMessage;

  const SyncScanResult({
    required this.status,
    required this.rootPath,
    required this.runId,
    required this.scannedCount,
    this.errorMessage,
  });
}

abstract class FileScannerService {
  ScanMode get scanMode;
  Stream<FileScanBatch> get result;
  Stream<WorkerState> get stateStream;

  Future<CachedScanSnapshot> loadCached(String path);
  Future<SyncScanResult> sync(String path, {required int runId});
  Future<void> cancel();
  void dispose();

  factory FileScannerService(ScanMode scanMode) {
    return _FileScannerServiceImpl(scanMode);
  }
}

class _FileScannerServiceImpl implements FileScannerService {
  @override
  final ScanMode scanMode;

  _FileScannerServiceImpl(this.scanMode);

  final _worker = FileScanWorker();
  final _resultController = StreamController<FileScanBatch>.broadcast();
  final _treeBuilder = IncrementalTreeBuilder();
  late final _storage = FileScannerStorage();
  final Set<String> _visitedPaths = {};

  int _baselineScannedCount = 0;
  int _currentRunId = 0;
  bool _cancelRequested = false;

  @override
  Stream<FileScanBatch> get result => _resultController.stream;

  @override
  Stream<WorkerState> get stateStream => _worker.stateStream;

  @override
  Future<CachedScanSnapshot> loadCached(String rootPath) async {
    _treeBuilder.clear(keepRootPath: false);
    _treeBuilder.setRootPath(rootPath);

    final meta = _storage.getRootMeta(scanMode, rootPath);
    final hasIndex = _storage.hasRootIndex(scanMode, rootPath);
    final cachedNodes = _storage.getNodesByRootPath(scanMode, rootPath);
    final cachedCount = meta?.cachedFileCount ?? _countFlatFiles(cachedNodes);
    final hasCachedData =
        cachedNodes.isNotEmpty || hasIndex || meta?.lastSuccessfulScanAt != null;

    _baselineScannedCount = cachedCount;

    if (cachedNodes.isNotEmpty) {
      _treeBuilder.mergeChunk(cachedNodes);
    }

    if (cachedNodes.isNotEmpty && meta == null) {
      unawaited(
        _storage.saveRootMeta(
          scanMode,
          rootPath,
          RootScanMeta(cachedFileCount: cachedCount),
        ),
      );
    }

    return CachedScanSnapshot(
      nodes: List<FileNode>.from(_treeBuilder.roots),
      meta: meta,
      scannedCount: cachedCount,
      hasCachedData: hasCachedData,
    );
  }

  @override
  Future<SyncScanResult> sync(String path, {required int runId}) async {
    await cancel();

    _currentRunId = runId;
    _cancelRequested = false;

    final previousMeta = _storage.getRootMeta(scanMode, path);
    final previousNodes = _storage.getNodesByRootPath(scanMode, path);
    final hadStableSnapshot = previousNodes.isNotEmpty ||
        _storage.hasRootIndex(scanMode, path) ||
        previousMeta?.lastSuccessfulScanAt != null;

    final startedAt = DateTime.now();
    await _storage.saveRootMeta(
      scanMode,
      path,
      (previousMeta ?? const RootScanMeta()).copyWith(
        lastAttemptAt: startedAt,
        cachedFileCount: previousMeta?.cachedFileCount ?? _baselineScannedCount,
      ),
    );

    try {
      final finalNodes = await _performSync(path, runId);
      if (_isRunStale(runId)) {
        return _restoreStableSnapshot(
          path: path,
          runId: runId,
          previousMeta: previousMeta,
          previousNodes: previousNodes,
          hadStableSnapshot: hadStableSnapshot,
          status: RootScanStatus.cancelled,
        );
      }

      final completedAt = DateTime.now();
      final finalCount = _countFlatFiles(finalNodes);
      _baselineScannedCount = finalCount;

      await _storage.replaceRootIndex(scanMode, path, finalNodes);
      await _storage.saveRootMeta(
        scanMode,
        path,
        (previousMeta ?? const RootScanMeta()).copyWith(
          lastSuccessfulScanAt: completedAt,
          lastAttemptAt: completedAt,
          lastScanStatus: RootScanStatus.success,
          cachedFileCount: finalCount,
          isDirty: false,
        ),
      );

      return SyncScanResult(
        status: SyncRunStatus.success,
        rootPath: path,
        runId: runId,
        scannedCount: finalCount,
      );
    } catch (error) {
      if (_isRunStale(runId)) {
        return _restoreStableSnapshot(
          path: path,
          runId: runId,
          previousMeta: previousMeta,
          previousNodes: previousNodes,
          hadStableSnapshot: hadStableSnapshot,
          status: RootScanStatus.cancelled,
        );
      }

      return _restoreStableSnapshot(
        path: path,
        runId: runId,
        previousMeta: previousMeta,
        previousNodes: previousNodes,
        hadStableSnapshot: hadStableSnapshot,
        status: RootScanStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    if (_worker.currentState == WorkerState.scanning) {
      _worker.dispose();
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _cancelRequested = true;
    _worker.dispose();
    _resultController.close();
  }

  bool _isRunStale(int runId) {
    return _cancelRequested || runId != _currentRunId;
  }

  Future<List<FileNode>> _performSync(String path, int runId) async {
    _visitedPaths.clear();

    final allParsedWorks = ScraperStorage().getAllWorks();
    final parsedRjCodes = allParsedWorks
        .expand((work) => [
              'RJ${work.id}'.toUpperCase(),
              'RJ0${work.id}'.toUpperCase(),
            ])
        .toSet();

    final chunkStream = _worker.start(
      parsedRjCodes: parsedRjCodes,
      path: path,
      extensions: scanMode.extensions,
      scanMode: scanMode,
      scanArchives: scanMode.scanArchives,
    );

    await for (final batch in chunkStream) {
      if (_isRunStale(runId)) {
        break;
      }

      final flatChunk = batch.nodes;
      final filesToUpdate = <FileNode>[];

      for (final node in flatChunk) {
        _markPathAndParentsAsVisited(node.keyId, path);

        final cachedNode = _storage.getNode(scanMode, node.keyId);
        if (cachedNode == null ||
            cachedNode.lastModified != node.lastModified ||
            cachedNode.nodeStatus != node.nodeStatus ||
            cachedNode.rjCode != node.rjCode) {
          filesToUpdate.add(node);
        }
      }

      if (filesToUpdate.isNotEmpty) {
        _treeBuilder.mergeChunk(filesToUpdate);
        final nodesToSave = _treeBuilder.consumeTouchedNodes();
        await _storage.saveNodes(scanMode, nodesToSave);
      }

      _emitCurrentResult(
        batch.scannedCount > _baselineScannedCount
            ? batch.scannedCount
            : _baselineScannedCount,
        rootPath: path,
        runId: runId,
      );
    }

    if (_isRunStale(runId)) {
      return previousNodesFromTree(path);
    }

    await _handleDeletedFiles(path, runId);
    if (_isRunStale(runId)) {
      return previousNodesFromTree(path);
    }

    return _storage.getNodesByRootPath(
      scanMode,
      path,
      preferIndex: false,
    );
  }

  List<FileNode> previousNodesFromTree(String rootPath) {
    _treeBuilder.clear(keepRootPath: false);
    _treeBuilder.setRootPath(rootPath);
    return const [];
  }

  Future<void> _handleDeletedFiles(String rootPath, int runId) async {
    final allCachedNodes = _storage.getNodesByRootPath(
      scanMode,
      rootPath,
      preferIndex: false,
    );
    final keysToDelete = <String>[];

    for (final node in allCachedNodes) {
      final normalizedKey = p.normalize(node.keyId).toLowerCase();
      if (!_visitedPaths.contains(normalizedKey)) {
        keysToDelete.add(node.keyId);
      }
    }

    if (keysToDelete.isNotEmpty) {
      debugPrint(
        'Scanner: Detected ${keysToDelete.length} deleted files. Cleaning up...',
      );
      await _storage.deleteNodes(scanMode, keysToDelete);
    }

    final remainingNodes = _storage.getNodesByRootPath(
      scanMode,
      rootPath,
      preferIndex: false,
    );
    _baselineScannedCount = _countFlatFiles(remainingNodes);
    _treeBuilder.rebuild(remainingNodes);
    _emitCurrentResult(
      _baselineScannedCount,
      rootPath: rootPath,
      runId: runId,
    );
  }

  Future<SyncScanResult> _restoreStableSnapshot({
    required String path,
    required int runId,
    required RootScanMeta? previousMeta,
    required List<FileNode> previousNodes,
    required bool hadStableSnapshot,
    required RootScanStatus status,
    String? errorMessage,
  }) async {
    await _storage.clearByRootPath(scanMode, path, preferIndex: false);

    if (hadStableSnapshot) {
      if (previousNodes.isNotEmpty) {
        await _storage.saveNodes(scanMode, previousNodes);
      }
      await _storage.replaceRootIndex(scanMode, path, previousNodes);
    }

    final restoredCount = previousMeta?.cachedFileCount ?? _countFlatFiles(previousNodes);
    final restoredMeta = (previousMeta ?? const RootScanMeta()).copyWith(
      lastAttemptAt: DateTime.now(),
      lastScanStatus: status,
      cachedFileCount: restoredCount,
    );
    await _storage.saveRootMeta(scanMode, path, restoredMeta);

    _baselineScannedCount = restoredCount;
    _treeBuilder.clear(keepRootPath: false);
    _treeBuilder.setRootPath(path);
    if (previousNodes.isNotEmpty) {
      _treeBuilder.mergeChunk(previousNodes);
    }
    _emitCurrentResult(
      restoredCount,
      rootPath: path,
      runId: runId,
    );

    return SyncScanResult(
      status: status == RootScanStatus.error
          ? SyncRunStatus.error
          : SyncRunStatus.cancelled,
      rootPath: path,
      runId: runId,
      scannedCount: restoredCount,
      errorMessage: errorMessage,
    );
  }

  void _markPathAndParentsAsVisited(String fullPath, String rootPath) {
    String currentPath = p.normalize(fullPath).toLowerCase();
    final lowerRoot = p.normalize(rootPath).toLowerCase();

    while (true) {
      _visitedPaths.add(currentPath);
      if (currentPath == lowerRoot || currentPath == p.dirname(currentPath)) {
        break;
      }
      currentPath = p.dirname(currentPath);
    }
  }

  void _emitCurrentResult(
    int scannedCount, {
    required String rootPath,
    required int runId,
  }) {
    if (_resultController.isClosed) return;
    _resultController.add(
      FileScanBatch(
        nodes: List<FileNode>.from(_treeBuilder.roots),
        scannedCount: scannedCount,
        rootPath: rootPath,
        runId: runId,
      ),
    );
  }

  int _countFlatFiles(List<FileNode> nodes) {
    return nodes.where((node) => !node.isFolder).length;
  }
}
