import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;

import 'archive_service.dart';

enum WorkerState { idle, scanning, done, error }

class FileScanWorker {
  static final RegExp _rjRegex = RegExp(r'RJ0?(\d{7,9})', caseSensitive: false);

  Future<List<FileNode>> start({
    required String path,
    required Set<String> extensions,
    required Set<int> parsedWorkIds,
    bool scanArchives = false,
  }) {
    final rootPath = _normalize(path);

    return Isolate.run(() async {
      final results = <FileNode>[];
      final dir = Directory(rootPath);
      if (!await dir.exists()) return results;

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;

        final filePath = _normalize(entity.path);
        final ext = _extension(filePath);
        if (ext == null) continue;

        if (extensions.contains(ext)) {
          results.add(_buildNode(
            filePath: filePath,
            rootPath: rootPath,
            ext: ext,
            lastModified: _modified(entity),
            parsedWorkIds: parsedWorkIds,
          ));
          continue;
        }

        if (scanArchives && ArchiveService.isArchive(filePath)) {
          final archiveModified = _modified(entity);
          final entries = await ArchiveService.scanZip(entity, allowedExts: extensions);

          for (final entry in entries) {
            final virtualPath = _normalize(entry.virtualPath);
            final virtualExt = _extension(virtualPath);
            if (virtualExt == null || !extensions.contains(virtualExt)) continue;

            results.add(_buildNode(
              filePath: virtualPath,
              rootPath: rootPath,
              ext: virtualExt,
              lastModified: archiveModified,
              size: entry.size,
              parsedWorkIds: parsedWorkIds,
            ));
          }
        }
      }

      return results;
    });
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
    return id == null ? (NodeSource.localSingle, null) : (NodeSource.localWork, id);
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