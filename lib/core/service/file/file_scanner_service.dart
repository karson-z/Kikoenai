import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/local_media/data/model/file_scanner_state.dart';

import '../../utils/scraper/scraper_storage.dart';
import 'file_node_library_index.dart';
import 'file_scanner_storage.dart';
import 'file_scanner_worker.dart';

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

  bool get scanArchives => this == ScanMode.subtitles;
}

class FileScannerResult {
  final List<FileNode> flatNodes;
  final int scannedCount;
  final String rootPath;

  const FileScannerResult({
    required this.flatNodes,
    required this.scannedCount,
    required this.rootPath,
  });
}

class FileScannerService {
  FileScannerService._();

  static final FileScannerService instance = FileScannerService._();

  final FileScanWorker _worker = FileScanWorker();

  final FileScannerStorage _storage = FileScannerStorage();

  final StreamController<FileScannerResult> _resultController =
      StreamController<FileScannerResult>.broadcast();

  final List<FileNode> _flatFiles = [];

  final Set<String> _visitedKeys = {};

  bool _disposed = false;

  Stream<FileScannerResult> get result => _resultController.stream;

  void dispose() {
    _disposed = true;

    if (!_resultController.isClosed) {
      _resultController.close();
    }
  }

  Future<void> startScan(ScanTarget scanTarget) async {
    await _initAndLoadCache(scanTarget);

    await _performSilentSync(scanTarget);
  }

  /// 初始化并加载本地缓存
  Future<void> _initAndLoadCache(ScanTarget scanTarget) async {
    _flatFiles
      ..clear()
      ..addAll(
        _storage
            .getNodesByRootPath(scanTarget.scanMode, scanTarget.path)
            .where((node) => !node.isFolder),
      );

    _emitCurrentResult(scanTarget.path);
  }

  /// 静默同步磁盘
  Future<void> _performSilentSync(ScanTarget scanTarget) async {
    _visitedKeys.clear();

    final parsedWorkIds = ScraperStorage()
        .getAllWorks()
        .map((work) => work.id)
        .toSet();

    final scannedNodes = await _worker.start(
      path: scanTarget.path,
      extensions: scanTarget.scanMode.extensions,
      parsedWorkIds: parsedWorkIds,
      scanArchives: scanTarget.scanMode.scanArchives,
    );

    final List<FileNode> filesToSave = [];

    for (final node in scannedNodes) {
      final key = node.keyId;

      if (key.isEmpty) continue;

      _visitedKeys.add(_normalizeKey(key));

      final cached = _storage.getNode(scanTarget.scanMode, key);

      if (_shouldSave(cached, node)) {
        filesToSave.add(node);
      }
    }

    final List<String> keysToDelete = [];

    for (final cached in _flatFiles) {
      final key = cached.keyId;

      if (key.isEmpty) continue;

      if (!_visitedKeys.contains(_normalizeKey(key))) {
        keysToDelete.add(key);
      }
    }

    /// 删除已不存在文件
    if (keysToDelete.isNotEmpty) {
      await _storage.deleteNodes(scanTarget.scanMode, keysToDelete);

      _flatFiles.removeWhere((node) => keysToDelete.contains(node.keyId));
    }

    /// 保存新增/更新文件
    if (filesToSave.isNotEmpty) {
      await _storage.saveNodes(scanTarget.scanMode, filesToSave);

      for (final updated in filesToSave) {
        final index = _flatFiles.indexWhere(
          (node) => node.keyId == updated.keyId,
        );

        if (index >= 0) {
          _flatFiles[index] = updated;
        } else {
          _flatFiles.add(updated);
        }
      }
    }

    debugPrint(
      '[FileScannerService] '
      '${scanTarget.scanMode.name}: '
      '${_flatFiles.length} files indexed.',
    );

    _emitCurrentResult(scanTarget.path);
  }

  bool _shouldSave(FileNode? cached, FileNode next) {
    return cached == null ||
        cached.lastModified != next.lastModified ||
        cached.nodeStatus != next.nodeStatus ||
        cached.source != next.source ||
        cached.workId != next.workId ||
        cached.path != next.path ||
        cached.folderPath != next.folderPath ||
        cached.rootPath != next.rootPath;
  }

  void _emitCurrentResult(String rootPath) {
    _resultController.add(FileScannerResult(flatNodes: _flatFiles, scannedCount: _flatFiles.length, rootPath:rootPath ));
  }

  String _normalizeKey(String value) {
    return FileNodeLibraryIndex.normalizePath(value).toLowerCase();
  }
}
