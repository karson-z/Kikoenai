import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/local_media/model/local_media_exclusion.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

/// 批量解析、播放和排除的纯操作。
///
/// 页面只负责取状态和展示结果，具体筛选与收集放在这里，方便单独测试。
class FileBrowserEditActions {
  const FileBrowserEditActions._();

  /// 当前目录里可以加入解析队列的 RJ 文件夹。
  ///
  /// 已经在作品库或解析队列中的作品会被跳过。
  static List<FileNode> parseCandidates({
    required List<FileNode> directoryNodes,
    required Set<int> parsedWorkIds,
    required ScraperQueueState queue,
  }) {
    final queued = {
      for (final node in [...queue.pending, ...queue.processing, ...queue.paused])
        if (node.workId != null) node.workId!,
    };
    return directoryNodes.where((node) {
      if (!node.isFolder) return false;
      final workId = node.workId ?? RjCode.parse(node.title);
      if (workId == null) return false;
      return !parsedWorkIds.contains(workId) && !queued.contains(workId);
    }).toList(growable: false);
  }

  /// 从本地索引收集已选项里的可播放媒体。
  ///
  /// 排除文件夹内部的文件不会进入结果。
  static List<FileNode> collectLocalPlayable({
    required FileNodeLibraryIndex index,
    required List<FileNode> selected,
  }) {
    final result = <FileNode>[];
    final seen = <String>{};
    for (final node in selected) {
      if (node.isFolder) {
        final path = node.path;
        if (path == null) continue;
        for (final file in index.getFilesInFolder(
          NodeFolder(path),
          recursive: true,
        )) {
          _addPlayable(result, seen, file, index);
        }
        continue;
      }
      _addPlayable(result, seen, node, index);
    }
    return result;
  }

  static void _addPlayable(
    List<FileNode> result,
    Set<String> seen,
    FileNode node,
    FileNodeLibraryIndex index,
  ) {
    if (!node.isPlayable) return;
    final path = node.effectivePath;
    if (index.isExcluded(path, isFolder: false)) return;
    if (!seen.add(node.keyId)) return;
    result.add(node);
  }

  /// 递归请求网盘目录并收集可播放媒体。
  ///
  /// 单个目录失败时继续处理其余目录，并计入 [CloudPlayableCollection.failedDirectories]。
  static Future<CloudPlayableCollection> collectCloudPlayable({
    required CloudDriveSource source,
    required List<FileNode> selected,
    int concurrency = 3,
    void Function(CloudPlayableProgress progress)? onProgress,
  }) async {
    final files = <FileNode>[];
    final seen = <String>{};
    final pending = <String>[];
    var failed = 0;

    for (final node in selected) {
      if (node.isFolder) {
        final path = node.path;
        if (path != null && path.isNotEmpty) pending.add(path);
        continue;
      }
      if (node.isPlayable && seen.add(node.keyId)) files.add(node);
    }

    var completed = 0;
    Future<void> report() async {
      onProgress?.call(
        CloudPlayableProgress(
          completedDirectories: completed,
          pendingDirectories: pending.length,
          collectedFiles: files.length,
          failedDirectories: failed,
        ),
      );
    }

    await report();
    while (pending.isNotEmpty) {
      final batch = pending.take(concurrency).toList(growable: false);
      pending.removeRange(0, batch.length);
      final results = await Future.wait(
        batch.map((path) async {
          try {
            return await _listAll(source, path);
          } catch (_) {
            return null;
          }
        }),
      );
      for (final result in results) {
        completed++;
        if (result == null) {
          failed++;
          continue;
        }
        for (final node in result) {
          if (node.isFolder) {
            final path = node.path;
            if (path != null && path.isNotEmpty) pending.add(path);
            continue;
          }
          if (node.isPlayable && seen.add(node.keyId)) files.add(node);
        }
      }
      await report();
    }

    return CloudPlayableCollection(files: files, failedDirectories: failed);
  }

  static Future<List<FileNode>> _listAll(
    CloudDriveSource source,
    String path,
  ) async {
    final items = <FileNode>[];
    var page = 1;
    while (true) {
      final result = await source.list(path: path, page: page, pageSize: 200);
      items.addAll(result.items);
      if (!source.supportsPagination || items.length >= result.totalCount) {
        return items;
      }
      if (result.items.isEmpty) return items;
      page++;
    }
  }

  static List<LocalMediaExclusion> exclusionsFor({
    required String rootPath,
    required List<FileNode> selected,
  }) {
    final root = NodeFolder.normalizePath(rootPath);
    return selected
        .map((node) {
          final path = node.path ?? node.mediaStreamUrl;
          if (path == null || path.isEmpty) return null;
          final relative = _relative(root, path);
          if (relative == null || relative.isEmpty) return null;
          return LocalMediaExclusion(
            rootPath: root,
            relativePath: relative,
            isFolder: node.isFolder,
          );
        })
        .whereType<LocalMediaExclusion>()
        .toList(growable: false);
  }

  static String? _relative(String root, String path) {
    final target = NodeFolder.normalizePath(path);
    final rootKey = root.toLowerCase();
    final targetKey = target.toLowerCase();
    if (!targetKey.startsWith('$rootKey/')) return null;
    return target.substring(root.length + 1);
  }

  /// 按每个文件自己的作品和来源生成播放项。
  static List<PlaybackItem> playbackItems(
    List<FileNode> files, {
    Work? Function(FileNode node)? workOf,
  }) {
    return files
        .map(
          (node) => PlaybackItem.fromFileNode(
            node,
            work: workOf?.call(node),
            source: node.source,
          ),
        )
        .toList(growable: false);
  }
}

class CloudPlayableProgress {
  const CloudPlayableProgress({
    required this.completedDirectories,
    required this.pendingDirectories,
    required this.collectedFiles,
    required this.failedDirectories,
  });

  final int completedDirectories;
  final int pendingDirectories;
  final int collectedFiles;
  final int failedDirectories;
}

class CloudPlayableCollection {
  const CloudPlayableCollection({
    required this.files,
    required this.failedDirectories,
  });

  final List<FileNode> files;
  final int failedDirectories;
}
