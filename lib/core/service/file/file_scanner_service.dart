import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import '../../utils/scraper/scraper_storage.dart';
import 'file_scanner_storage.dart';
import 'file_scanner_worker.dart';
import 'package:path/path.dart' as p;

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

class FileScanBatch {
  final List<FileNode> nodes;
  final int scannedCount;

  const FileScanBatch({
    required this.nodes,
    required this.scannedCount,
  });
}

class FileScannerService {
  final ScanMode scanMode;
  final _worker = FileScanWorker();
  final _resultController = StreamController<FileScanBatch>.broadcast();
  late final _storage = FileScannerStorage();

  final List<FileNode> _flatFiles = [];
  final Set<String> _visitedPaths = {};
  int _baselineScannedCount = 0;

  FileScannerService(this.scanMode);

  Stream<FileScanBatch> get result => _resultController.stream;

  void dispose() {
    _resultController.close();
  }

  /// 启动扫描主入口
  Future<void> startScan(String path) async {
    await _initAndLoadCache(path);
    await _performSilentSync(path);
  }

  Future<void> _initAndLoadCache(String rootPath) async {
    _flatFiles.clear();
    final cachedNodes = _storage.getNodesByRootPath(scanMode, rootPath);
    final cachedFiles = cachedNodes.where((node) => !node.isFolder).toList();

    _baselineScannedCount = cachedFiles.length;
    _flatFiles.addAll(cachedFiles);
    _emitCurrentResult(_baselineScannedCount);
  }

  Future<void> _performSilentSync(String path) async {
    _visitedPaths.clear();
    final allParsedWorks = ScraperStorage().getAllWorks();
    final parsedWorkIds = allParsedWorks.map((w) => w.id).toSet();

    // 后台非流式任务一次性读取全量合规数据
    final fileNodes = await _worker.start(
      path: path,
      extensions: scanMode.extensions,
      parsedWorkIds: parsedWorkIds,
      scanArchives: scanMode.scanArchives,
    );

    await _processScannedNodes(fileNodes);
    await _handleDeletedFiles(path);
  }

  Future<void> _processScannedNodes(List<FileNode> scannedNodes) async {
    final List<FileNode> filesToUpdate = [];

    for (var node in scannedNodes) {
      final normalizedKey = p.normalize(node.keyId).toLowerCase();
      _visitedPaths.add(normalizedKey);

      final cachedNode = _storage.getNode(scanMode, node.keyId);

      if (cachedNode == null ||
          cachedNode.lastModified != node.lastModified ||
          cachedNode.nodeStatus != node.nodeStatus ||
          cachedNode.source != node.source ||
          cachedNode.workId != node.workId) {
        filesToUpdate.add(node);
      }
    }

    if (filesToUpdate.isNotEmpty) {
      await _storage.saveNodes(scanMode, filesToUpdate);

      for (final updatedNode in filesToUpdate) {
        final index = _flatFiles.indexWhere((n) => n.keyId == updatedNode.keyId);
        if (index != -1) {
          _flatFiles[index] = updatedNode;
        } else {
          _flatFiles.add(updatedNode);
        }
      }
    }

    _emitCurrentResult(_flatFiles.length);
  }

  Future<void> _handleDeletedFiles(String rootPath) async {
    final allCachedNodes = _storage.getNodesByRootPath(scanMode, rootPath);
    final List<String> keysToDelete = [];

    for (var node in allCachedNodes) {
      final normalizedKey = p.normalize(node.keyId).toLowerCase();
      if (!_visitedPaths.contains(normalizedKey)) {
        keysToDelete.add(node.keyId);
      }
    }

    if (keysToDelete.isNotEmpty) {
      debugPrint("Scanner: Detected ${keysToDelete.length} deleted files. Cleaning up...");
      await _storage.deleteNodes(scanMode, keysToDelete);

      _flatFiles.removeWhere((n) => keysToDelete.contains(n.keyId));

      final remainingNodes = _storage.getNodesByRootPath(scanMode, rootPath);
      _baselineScannedCount = remainingNodes.where((n) => !n.isFolder).length;
      _emitCurrentResult(_baselineScannedCount);
    }
  }

  void _emitCurrentResult(int scannedCount) {
    _resultController.add(FileScanBatch(
      nodes: List.of(_flatFiles),
      scannedCount: scannedCount,
    ));
  }
}