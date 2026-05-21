import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'archive_service.dart';

class FileScanWorker {
  static final RegExp _rjRegex = RegExp(r'RJ(\d{7,9})', caseSensitive: false);

  /// 启动扁平化扫描，任务完全结束后直接返回文件节点列表
  Future<List<FileNode>> start({
    required String path,
    required Set<String> extensions,
    required Set<int> parsedWorkIds,
    bool scanArchives = false,
  }) {
    final normalizedRoot = path.replaceAll('\\', '/');

    return Isolate.run(() async {
      final List<FileNode> results = [];
      final dir = Directory(normalizedRoot);
      if (!await dir.exists()) return results;

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final filePath = entity.path;
          final lastDotIndex = filePath.lastIndexOf('.');
          if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) continue;
          final ext = filePath.substring(lastDotIndex).toLowerCase();

          if (extensions.contains(ext)) {
            final normalizedPath = filePath.replaceAll('\\', '/');
            int lastMod = 0;
            try {
              lastMod = entity.statSync().modified.millisecondsSinceEpoch;
            } catch (_) {}

            final (source, workId) = _resolveSourceAndWorkId(normalizedPath);

            // 根据是否有 RJ 号以及是否在已解析集合中确立节点状态
            NodeStatus nodeStatus = NodeStatus.normal;
            if (source == NodeSource.localWork && workId != null) {
              nodeStatus = parsedWorkIds.contains(workId)
                  ? NodeStatus.parsed
                  : NodeStatus.pending;
            }

            results.add(FileNode(
              mediaStreamUrl: normalizedPath,
              mediaDownloadUrl: normalizedPath,
              type: _determineNodeType(ext),
              title: normalizedPath.split('/').last,
              lastModified: lastMod,
              nodeStatus: nodeStatus,
              workId: workId,
              source: source,
            ));
          } else if (scanArchives && ArchiveService.isArchive(filePath)) {
            try {
              int archiveLastMod = 0;
              try {
                archiveLastMod = entity.statSync().modified.millisecondsSinceEpoch;
              } catch (_) {}

              final entries = await ArchiveService.scanZip(entity, allowedExts: extensions);

              for (var entry in entries) {
                final virtualPath = entry.virtualPath;
                final zipLastDotIndex = virtualPath.lastIndexOf('.');
                if (zipLastDotIndex == -1 || zipLastDotIndex == virtualPath.length - 1) continue;
                final zipExt = virtualPath.substring(zipLastDotIndex).toLowerCase();

                if (extensions.contains(zipExt)) {
                  final normalizedVirtualPath = virtualPath.replaceAll('\\', '/');
                  final normalizedArchivePath = filePath.replaceAll('\\', '/');
                  final combinedPath = '$normalizedArchivePath/$normalizedVirtualPath';
                  final (source, workId) = _resolveSourceAndWorkId(combinedPath);

                  // 压缩包内虚拟节点同样执行对齐的状态判定
                  NodeStatus nodeStatus = NodeStatus.normal;
                  if (source == NodeSource.localWork && workId != null) {
                    nodeStatus = parsedWorkIds.contains(workId)
                        ? NodeStatus.parsed
                        : NodeStatus.pending;
                  }

                  results.add(FileNode(
                    mediaStreamUrl: normalizedVirtualPath,
                    mediaDownloadUrl: normalizedVirtualPath,
                    type: _determineNodeType(zipExt),
                    title: normalizedVirtualPath.split('/').last,
                    lastModified: archiveLastMod,
                    nodeStatus: nodeStatus,
                    workId: workId,
                    source: source,
                  ));
                }
              }
            } catch (_) {}
          }
        }
      }
      return results;
    });
  }

  static (NodeSource, int?) _resolveSourceAndWorkId(String path) {
    final match = _rjRegex.firstMatch(path);
    if (match != null) {
      final idStr = match.group(1);
      if (idStr != null) {
        return (NodeSource.localWork, int.tryParse(idStr));
      }
    }
    return (NodeSource.localSingle, null);
  }

  static NodeType _determineNodeType(String ext) {
    if (FileExtensions.audio.contains(ext)) return NodeType.audio;
    if (FileExtensions.video.contains(ext)) return NodeType.video;
    if (FileExtensions.subtitles.contains(ext)) return NodeType.text;
    return NodeType.unknown;
  }
}