import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/local_media/data/model/file_scanner_state.dart';

import '../../utils/scraper/scraper_storage.dart';
import 'file_node_library_index.dart';
import 'file_scanner_storage.dart';
import 'file_scanner_worker.dart';

class FileSyncProgress {
  final ScanTarget target;
  final int scannedFileCount;
  final int discoveredNodeCount;
  final int savedNodeCount;

  const FileSyncProgress({
    required this.target,
    required this.scannedFileCount,
    required this.discoveredNodeCount,
    required this.savedNodeCount,
  });
}

class FileSyncSummary {
  final ScanTarget target;
  final int indexedCount;
  final int scannedFileCount;
  final int discoveredNodeCount;
  final int savedNodeCount;
  final int deletedStaleCount;

  const FileSyncSummary({
    required this.target,
    required this.indexedCount,
    required this.scannedFileCount,
    required this.discoveredNodeCount,
    required this.savedNodeCount,
    required this.deletedStaleCount,
  });
}

typedef FileSyncProgressCallback = void Function(FileSyncProgress progress);

class FileScanSyncEngine {
  FileScanSyncEngine({FileScanWorker? worker, FileScannerStorage? storage})
    : _worker = worker ?? FileScanWorker(),
      _storage = storage ?? FileScannerStorage();

  final FileScanWorker _worker;
  final FileScannerStorage _storage;

  Future<FileSyncSummary> syncTarget({
    required ScanTarget target,
    List<FileNode>? inMemoryNodes,
    FileSyncProgressCallback? onProgress,
  }) async {
    final nodes =
        inMemoryNodes ??
        _storage
            .getNodesByRootPath(target.scanMode, target.path)
            .where((node) => !node.isFolder)
            .toList();

    final visitedKeys = <String>{};
    final nodeIndexByKey = <String, int>{
      for (var index = 0; index < nodes.length; index++)
        if (nodes[index].keyId.isNotEmpty)
          _normalizeKey(nodes[index].keyId): index,
    };
    final cachedNodeByKey = <String, FileNode>{
      for (final node in nodes)
        if (node.keyId.isNotEmpty) _normalizeKey(node.keyId): node,
    };

    final parsedWorkIds = ScraperStorage()
        .getAllWorks()
        .map((work) => work.id)
        .toSet();

    var discoveredNodeCount = 0;
    var scannedFileCount = 0;
    var savedNodeCount = 0;

    await for (final batch in _worker.startStream(
      path: target.path,
      extensions: _extensionsFor(target),
      parsedWorkIds: parsedWorkIds,
      scanArchives: _shouldScanArchives(target),
    )) {
      discoveredNodeCount += batch.nodes.length;
      scannedFileCount = batch.scannedFileCount;

      final filesToSave = <FileNode>[];

      for (final node in batch.nodes) {
        final key = node.keyId;
        if (key.isEmpty) continue;

        final normalizedKey = _normalizeKey(key);
        visitedKeys.add(normalizedKey);

        final cached = cachedNodeByKey[normalizedKey];
        if (_shouldSave(cached, node)) {
          filesToSave.add(node);
        }
      }

      if (filesToSave.isNotEmpty) {
        await _storage.saveNodes(target.scanMode, filesToSave);
        savedNodeCount += filesToSave.length;

        for (final updated in filesToSave) {
          final normalizedKey = _normalizeKey(updated.keyId);
          final index = nodeIndexByKey[normalizedKey];

          if (index != null) {
            nodes[index] = updated;
          } else {
            nodeIndexByKey[normalizedKey] = nodes.length;
            nodes.add(updated);
          }
          cachedNodeByKey[normalizedKey] = updated;
        }
      }

      onProgress?.call(
        FileSyncProgress(
          target: target,
          scannedFileCount: scannedFileCount,
          discoveredNodeCount: discoveredNodeCount,
          savedNodeCount: savedNodeCount,
        ),
      );
    }

    final keysToDelete = <String>[];

    for (final cached in nodes) {
      final key = cached.keyId;
      if (key.isEmpty) continue;

      if (!visitedKeys.contains(_normalizeKey(key))) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _storage.deleteNodes(target.scanMode, keysToDelete);
      final normalizedKeysToDelete = keysToDelete.map(_normalizeKey).toSet();
      nodes.removeWhere((node) {
        final key = node.keyId;
        return key.isNotEmpty &&
            normalizedKeysToDelete.contains(_normalizeKey(key));
      });
    }

    debugPrint(
      '[FileScanSyncEngine] '
      '${target.scanMode.name}: '
      '${nodes.length} files indexed, '
      '$discoveredNodeCount nodes discovered, '
      '$scannedFileCount physical files scanned.',
    );

    return FileSyncSummary(
      target: target,
      indexedCount: nodes.length,
      scannedFileCount: scannedFileCount,
      discoveredNodeCount: discoveredNodeCount,
      savedNodeCount: savedNodeCount,
      deletedStaleCount: keysToDelete.length,
    );
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

  String _normalizeKey(String value) {
    return FileNodeLibraryIndex.normalizePath(value).toLowerCase();
  }

  Set<String> _extensionsFor(ScanTarget target) {
    switch (target.scanMode.name) {
      case 'audio':
        return FileExtensions.audio;
      case 'video':
        return FileExtensions.video;
      case 'subtitles':
        return FileExtensions.subtitles;
    }

    return const {};
  }

  bool _shouldScanArchives(ScanTarget target) {
    return target.scanMode.name == 'subtitles';
  }
}
