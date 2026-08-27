import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai/core/widgets/menu/menu.dart';
import 'package:kikoenai/core/widgets/text_preview/text_preview_page.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';
import 'package:kikoenai/features/local_media/widget/file_operation_sheet.dart';
import 'package:kikoenai/features/local_media/widget/status_pill.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';

/// 统一文件浏览器的功能开关。
///
/// 本地媒体与专辑详情两种场景通过此配置区分 tile 行为，避免在视图层用 `if` 切换。
class FileBrowserConfig {
  /// 显示“本地”下载标记，并对网络文件做本地路径替换（专辑详情-网络用）。
  final bool showDownloadBadge;

  /// 显示文件夹状态药丸 + 子项数（本地媒体用）。
  final bool showFolderStatus;

  /// 字幕模式：点击文件复制路径而非播放（本地媒体-字幕扫描用）。
  final bool subtitlesCopyMode;

  /// 启用文件夹/文件长按操作面板（本地媒体用）。
  final bool enableFolderLongPress;

  /// 启用图片预览（专辑详情用）。
  final bool enableImagePreview;

  /// 启用文本预览（专辑详情用）。
  final bool enableTextPreview;

  /// 启用音频右键菜单“加入播放列表”（专辑详情用）。
  final bool enableAudioContextMenu;

  /// 文件夹右侧是否显示进入箭头（如 `>`）。
  ///
  /// 默认关闭，避免文件夹条目同时出现左侧图标和右侧箭头两套视觉提示。
  /// 需要明确提示“可进入下一级”的界面（如本地媒体库）可手动开启。
  final bool showFolderEnterIcon;

  /// 文件条目副标题显示大小与修改时间（Alist 文件系统用）。
  ///
  /// 开启后，非文件夹节点副标题展示 `大小 • 修改时间`。
  final bool showFileMetaInfo;

  const FileBrowserConfig({
    this.showDownloadBadge = false,
    this.showFolderStatus = false,
    this.subtitlesCopyMode = false,
    this.enableFolderLongPress = false,
    this.enableImagePreview = false,
    this.enableTextPreview = false,
    this.enableAudioContextMenu = false,
    this.showFolderEnterIcon = false,
    this.showFileMetaInfo = false,
  });
}

/// 统一的文件节点浏览器。
///
/// 本地媒体扫描页与作品详情页共用此组件，数据源统一规整为
/// [FileNodeLibraryIndex]（由调用方持有索引并传入 [currentNodes]）。
/// 本组件只负责渲染当前层级的节点列表 + 处理点击/预览/播放等交互，
/// 不持有导航状态；进入文件夹 / 返回上一级由调用方通过回调驱动。
///
/// 返回一个 Sliver，调用方按需放入 [CustomScrollView]：
/// - 专辑详情：与吸顶面包屑头一起包进 `SliverMainAxisGroup`。
/// - 本地媒体：单独放进一个 `CustomScrollView`。
class FileNodeBrowser extends ConsumerStatefulWidget {
  const FileNodeBrowser({
    super.key,
    required this.currentNodes,
    required this.work,
    required this.source,
    required this.config,
    required this.onEnterFolder,
    this.workResolver,
    this.sourceResolver,
    this.onOpenFile,
  });

  /// 当前层级的直接子节点（由调用方从 `FileNodeLibraryIndex.currentChildren` 取）。
  final List<FileNode> currentNodes;

  /// 默认作品（专辑详情用）。本地媒体传 null，改由 [workResolver] 按节点解析。
  final Work? work;

  /// 默认来源（专辑详情用）。本地媒体改由 [sourceResolver] 按节点解析。
  final NodeSource source;

  /// 功能开关。
  final FileBrowserConfig config;

  /// 进入文件夹回调。调用方负责更新索引并触发重建。
  final void Function(FileNode folder) onEnterFolder;

  /// 按节点解析作品（本地媒体用）。为 null 时回退到 [work]。
  final Work? Function(FileNode node)? workResolver;

  /// 按节点解析来源（本地媒体用）。为 null 时回退到 [source]。
  final NodeSource Function(FileNode node)? sourceResolver;

  /// Overrides the default preview/play behavior for non-folder entries.
  final FutureOr<void> Function(FileNode node, List<FileNode> siblings)? onOpenFile;

  @override
  ConsumerState<FileNodeBrowser> createState() => _FileNodeBrowserState();
}

class _FileNodeBrowserState extends ConsumerState<FileNodeBrowser> {
  @override
  void initState() {
    super.initState();
    // 仅在需要下载标记时刷新下载任务记录。
    if (widget.config.showDownloadBadge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(allTasksProvider.notifier).refreshTasks();
      });
    }
  }

  Map<String, TaskRecord> _buildDownloadedTaskMap() {
    if (!widget.config.showDownloadBadge) return const {};
    final taskList = ref.watch(completedTasksProvider);
    return {for (var record in taskList) record.task.taskId: record};
  }

  /// 为已下载节点附加本地文件路径：[localMediaUrl]（保留远程 [mediaStreamUrl]，
  /// 不覆盖）。播放时由 [FileNode.playablePath] 优先本地、回退远端。
  Future<List<FileNode>> _resolveLocalPathNodes(
    List<FileNode> nodes,
    Map<String, TaskRecord> taskMap,
  ) async {
    if (taskMap.isEmpty) return nodes;
    final resolvedNodes = <FileNode>[];
    for (final node in nodes) {
      final record = taskMap[node.hash];
      if (record != null) {
        final localPath = await _resolveDownloadedLocalPath(record);
        if (localPath == null) {
          resolvedNodes.add(node);
          continue;
        }
        resolvedNodes.add(node.copyWith(localMediaUrl: localPath));
        continue;
      }
      resolvedNodes.add(node);
    }
    return resolvedNodes;
  }

  Future<String?> _resolveDownloadedLocalPath(TaskRecord record) async {
    final task = record.task;
    final localPath = await task.filePath();
    if (await File(localPath).exists()) return localPath;
    await ref.read(allTasksProvider.notifier).deleteRecordOnly(task.taskId);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final downloadedTaskMap = _buildDownloadedTaskMap();

    if (widget.currentNodes.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('该目录为空')),
      );
    }

    return SliverList.builder(
      itemCount: widget.currentNodes.length,
      itemBuilder: (_, index) {
        final node = widget.currentNodes[index];
        final bool isDownloaded =
            widget.config.showDownloadBadge &&
            downloadedTaskMap.containsKey(node.hash);
        return _buildTile(
          context,
          node,
          widget.currentNodes,
          isDownloaded,
          downloadedTaskMap,
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    FileNode node,
    List<FileNode> contextNodes,
    bool isDownloaded,
    Map<String, TaskRecord> downloadedTaskMap,
  ) {
    final tile = ListTile(
      leading: _buildLeading(node),
      title: Text(node.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(node),
      trailing: _buildTrailing(node, isDownloaded),
      onTap: () => _handleTap(context, node, contextNodes, downloadedTaskMap),
      onLongPress: widget.config.enableFolderLongPress
          ? () => FolderActionBottomSheet.show(context, node)
          : null,
    );

    if (node.isAudio && widget.config.enableAudioContextMenu) {
      return ContextMenuWrapper(
        items: const [
          PopupMenuItem(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('添加到播放列表'),
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == 'add') {
            FileNode nodeToAdd = node;
            final record = downloadedTaskMap[node.hash];
            if (record != null) {
              final localPath = await _resolveDownloadedLocalPath(record);
              if (localPath != null) {
                nodeToAdd = node.copyWith(localMediaUrl: localPath);
              }
            }
            ref
                .read(playerControllerProvider.notifier)
                .addSingleInQueue(
                  nodeToAdd,
                  _resolveWork(node),
                  source: _resolveSource(node),
                );
            KikoenaiToast.success('已添加到播放列表');
          }
        },
        child: tile,
      );
    }
    return tile;
  }

  Widget _buildLeading(FileNode node) {
    // 统一使用带颜色的图标，避免同一组件内出现“彩色 / 灰色”两套视觉风格。
    if (node.isFolder) {
      final isArchiveFolder = FileExtensions.isArchive(node.title);
      return Icon(
        isArchiveFolder ? Icons.folder_zip : Icons.folder,
        color: isArchiveFolder ? Colors.purpleAccent : Colors.amber,
      );
    }
    final fileType = FileExtensions.getFileType(node.title);
    return Icon(
      _localStyleIcon(fileType),
      color: _localStyleIconColor(fileType),
    );
  }

  Widget? _buildSubtitle(FileNode node) {
    if (widget.config.showFolderStatus) {
      if (node.isFolder) {
        final itemCount = node.subItemsCount;
        final itemCountText = '$itemCount 项';
        return Text(
          node.workId != null
              ? 'RJ0${node.workId}  •  $itemCountText'
              : itemCountText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        );
      }
      return Text(
        node.mediaStreamUrl ?? '',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (widget.config.showFileMetaInfo && !node.isFolder) {
      final sizeText = _formatFileSize(node.size ?? 0);
      final modifiedText = node.lastModified > 0
          ? _formatDateTime(node.lastModified)
          : '-';
      return Text(
        '$sizeText  •  $modifiedText',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      );
    }

    // 专辑详情样式
    return Text(
      '${node.isAudio ? '时长:' : '类型：'}'
      '${node.isAudio ? TimeFormatter.formatSeconds(node.duration?.toInt() ?? 0) : node.type.name}',
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes <= 0) return '-';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }

  static String _formatDateTime(int millisecondsSinceEpoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Widget? _buildTrailing(FileNode node, bool isDownloaded) {
    if (widget.config.showFolderStatus && node.isFolder) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NodeStatusPill(status: node.nodeStatus),
          if (widget.config.showFolderEnterIcon) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ],
      );
    }
    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
            SizedBox(width: 4),
            Text(
              '本地',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Future<void> _handleTap(
    BuildContext context,
    FileNode node,
    List<FileNode> contextNodes,
    Map<String, TaskRecord> downloadedTaskMap,
  ) async {
    if (node.isFolder) {
      widget.onEnterFolder(node);
      return;
    }

    final onOpenFile = widget.onOpenFile;
    if (onOpenFile != null) {
      await onOpenFile(node, contextNodes);
      return;
    }

    // 字幕模式：复制路径
    if (widget.config.subtitlesCopyMode) {
      Clipboard.setData(
        ClipboardData(text: node.mediaStreamUrl ?? node.hash ?? ''),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制路径: ${node.title}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 图片预览
    if (node.isImage && widget.config.enableImagePreview) {
      _handleImagePreview(context, node, contextNodes);
      return;
    }

    // 文本预览
    if (node.isText && widget.config.enableTextPreview) {
      _handleTextPreview(context, node);
      return;
    }

    // 播放
    final playerController = ref.read(playerControllerProvider.notifier);
    List<FileNode> processedList = contextNodes;
    FileNode targetNode = node;
    if (widget.config.showDownloadBadge) {
      processedList = await _resolveLocalPathNodes(
        contextNodes,
        downloadedTaskMap,
      );
      targetNode = processedList.firstWhere(
        (n) => n.hash == node.hash,
        orElse: () => node,
      );
    }
    playerController.handleFileTap(
      targetNode,
      processedList,
      work: _resolveWork(node),
      source: _resolveSource(node),
    );
  }

  Work _resolveWork(FileNode node) {
    final resolved = widget.workResolver?.call(node);
    if (resolved != null) return resolved;
    return widget.work ?? Work(id: node.workId ?? 0);
  }

  NodeSource _resolveSource(FileNode node) {
    return widget.sourceResolver?.call(node) ?? widget.source;
  }

  void _handleImagePreview(
    BuildContext context,
    FileNode node,
    List<FileNode> currentNodes,
  ) {
    final imageNodes = currentNodes.where((n) => n.isImage).toList();
    final imageUrls = imageNodes
        .map((n) => n.mediaStreamUrl ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    final initialIndex = imageNodes.indexOf(node);
    if (imageUrls.isNotEmpty && initialIndex != -1) {
      context.push(
        AppRoutes.imageView,
        extra: {'urls': imageUrls, 'index': initialIndex},
      );
    }
  }

  void _handleTextPreview(BuildContext context, FileNode node) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextPreviewPage(
          url: node.mediaStreamUrl ?? '',
          title: node.title,
          siteId: node.siteId,
        ),
      ),
    );
  }

  // --- 图标映射助手 ---

  IconData _localStyleIcon(FileType fileType) {
    switch (fileType) {
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.video:
        return Icons.videocam;
      case FileType.subtitle:
        return Icons.subtitles;
      case FileType.image:
        return Icons.image;
      case FileType.archive:
        return Icons.folder_zip;
      case FileType.document:
        return Icons.description;
      case FileType.unknown:
        return Icons.insert_drive_file;
    }
  }

  Color _localStyleIconColor(FileType fileType) {
    switch (fileType) {
      case FileType.audio:
        return Colors.blue;
      case FileType.video:
        return Colors.orange;
      case FileType.subtitle:
        return Colors.teal;
      case FileType.image:
        return Colors.purple;
      case FileType.archive:
        return Colors.brown;
      case FileType.document:
        return Colors.blueGrey;
      case FileType.unknown:
        return Colors.grey;
    }
  }
}
