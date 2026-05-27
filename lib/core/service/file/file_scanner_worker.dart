import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;

import 'archive_service.dart';

enum WorkerState { idle, scanning, done, error }

class FileScanBatch {
  final List<FileNode> nodes;
  final int scannedFileCount;

  const FileScanBatch({required this.nodes, required this.scannedFileCount});
}

class FileScanWorker {
  static final RegExp _rjRegex = RegExp(r'RJ0?(\d{7,9})', caseSensitive: false);

  Future<List<FileNode>> start({
    required String path,
    required Set<String> extensions,
    required Set<int> parsedWorkIds,
    bool scanArchives = false,
    int batchSize = 1000,
  }) async {
    final results = <FileNode>[];

    await for (final batch in startStream(
      path: path,
      extensions: extensions,
      parsedWorkIds: parsedWorkIds,
      scanArchives: scanArchives,
      batchSize: batchSize,
    )) {
      results.addAll(batch.nodes);
    }

    return results;
  }

  Stream<FileScanBatch> startStream({
    required String path,
    required Set<String> extensions,
    required Set<int> parsedWorkIds,
    bool scanArchives = false,
    int batchSize = 1000,
  }) async* {
    final receivePort = ReceivePort();
    final request = _FileScanRequest(
      sendPort: receivePort.sendPort,
      rootPath: _normalize(path),
      extensions: extensions,
      parsedWorkIds: parsedWorkIds,
      scanArchives: scanArchives,
      batchSize: batchSize <= 0 ? 1000 : batchSize,
    );

    final isolate = await Isolate.spawn(_scanEntry, request);

    try {
      await for (final message in receivePort) {
        if (message is _FileScanBatchMessage) {
          yield FileScanBatch(
            nodes: message.nodes,
            scannedFileCount: message.scannedFileCount,
          );
          continue;
        }

        if (message is _FileScanErrorMessage) {
          throw StateError('${message.error}\n${message.stackTrace}');
        }

        if (message is _FileScanDoneMessage) {
          break;
        }
      }
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  static Future<void> _scanEntry(_FileScanRequest request) async {
    try {
      final batch = <FileNode>[];
      var scannedFileCount = 0;

      void flush() {
        if (batch.isEmpty) return;

        request.sendPort.send(
          _FileScanBatchMessage(
            nodes: List<FileNode>.from(batch),
            scannedFileCount: scannedFileCount,
          ),
        );
        batch.clear();
      }

      void addNode(FileNode node) {
        batch.add(node);
        if (batch.length >= request.batchSize) flush();
      }

      final dir = Directory(request.rootPath);
      if (!await dir.exists()) {
        request.sendPort.send(const _FileScanDoneMessage());
        return;
      }

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;

        scannedFileCount++;

        final filePath = _normalize(entity.path);
        final ext = _extension(filePath);
        if (ext == null) continue;

        if (request.extensions.contains(ext)) {
          addNode(
            _buildNode(
              filePath: filePath,
              rootPath: request.rootPath,
              ext: ext,
              lastModified: _modified(entity),
              parsedWorkIds: request.parsedWorkIds,
            ),
          );
          continue;
        }

        if (request.scanArchives && ArchiveService.isArchive(filePath)) {
          final archiveModified = _modified(entity);
          final entries = await ArchiveService.scanZip(
            entity,
            allowedExts: request.extensions,
          );

          for (final entry in entries) {
            final virtualPath = _normalize(entry.virtualPath);
            final virtualExt = _extension(virtualPath);
            if (virtualExt == null ||
                !request.extensions.contains(virtualExt)) {
              continue;
            }

            addNode(
              _buildNode(
                filePath: virtualPath,
                rootPath: request.rootPath,
                ext: virtualExt,
                lastModified: archiveModified,
                size: entry.size,
                parsedWorkIds: request.parsedWorkIds,
              ),
            );
          }
        }
      }

      flush();
      request.sendPort.send(const _FileScanDoneMessage());
    } catch (e, stackTrace) {
      request.sendPort.send(
        _FileScanErrorMessage(
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
  }

  static FileNode _buildNode({
    required String filePath,
    required String rootPath,
    required String ext,
    required int lastModified,
    required Set<int> parsedWorkIds,
    int? size,
  }) {
    final (source, workId) = _resolveSourceAndWorkId(filePath);
    final status = source == NodeSource.localWork && workId != null
        ? parsedWorkIds.contains(workId)
              ? NodeStatus.parsed
              : NodeStatus.pending
        : NodeStatus.normal;

    return FileNode(
      type: _determineNodeType(ext),
      title: filePath.split('/').last,
      path: filePath,
      mediaStreamUrl: filePath,
      mediaDownloadUrl: filePath,
      folderPath: _dirname(filePath),
      rootPath: rootPath,
      lastModified: lastModified,
      nodeStatus: status,
      workId: workId,
      size: size,
      source: source,
    );
  }

  static (NodeSource, int?) _resolveSourceAndWorkId(String path) {
    final match = _rjRegex.firstMatch(path);
    final id = match == null ? null : int.tryParse(match.group(1) ?? '');
    return id == null
        ? (NodeSource.localSingle, null)
        : (NodeSource.localWork, id);
  }

  static NodeType _determineNodeType(String ext) {
    if (FileExtensions.audio.contains(ext)) return NodeType.audio;
    if (FileExtensions.video.contains(ext)) return NodeType.video;
    if (FileExtensions.subtitles.contains(ext)) return NodeType.text;
    return NodeType.unknown;
  }

  static String _normalize(String value) {
    final posix = p.Context(style: p.Style.posix);
    return posix.normalize(value.replaceAll('\\', '/'));
  }

  static String _dirname(String value) {
    final posix = p.Context(style: p.Style.posix);
    return posix.dirname(_normalize(value));
  }

  static String? _extension(String path) {
    final index = path.lastIndexOf('.');
    if (index < 0 || index == path.length - 1) return null;
    return path.substring(index).toLowerCase();
  }

  static int _modified(File file) {
    try {
      return file.statSync().modified.millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }
}

class _FileScanRequest {
  final SendPort sendPort;
  final String rootPath;
  final Set<String> extensions;
  final Set<int> parsedWorkIds;
  final bool scanArchives;
  final int batchSize;

  const _FileScanRequest({
    required this.sendPort,
    required this.rootPath,
    required this.extensions,
    required this.parsedWorkIds,
    required this.scanArchives,
    required this.batchSize,
  });
}

class _FileScanBatchMessage {
  final List<FileNode> nodes;
  final int scannedFileCount;

  const _FileScanBatchMessage({
    required this.nodes,
    required this.scannedFileCount,
  });
}

class _FileScanErrorMessage {
  final String error;
  final String stackTrace;

  const _FileScanErrorMessage({required this.error, required this.stackTrace});
}

class _FileScanDoneMessage {
  const _FileScanDoneMessage();
}
