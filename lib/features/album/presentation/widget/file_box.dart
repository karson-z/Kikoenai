import 'package:background_downloader/background_downloader.dart'; // 必须导入，用于 TaskRecord 和 filePath()
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/download/download_service.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/download/presentation/provider/download_provider.dart';
import '../../../../core/theme/theme_view_model.dart';
import '../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../../core/widgets/menu/menu.dart';
import '../../../../core/widgets/player/provider/player_controller_provider.dart';
import '../../../../core/widgets/text_preview/text_preview_page.dart';
import '../../data/model/file_node.dart';
import '../viewmodel/provider/file_manage_provider.dart';
import 'file_download_dialog.dart';

class FileNodeBrowser extends ConsumerStatefulWidget {
  final Work work;
  final List<FileNode> rootNodes;

  const FileNodeBrowser({
    super.key,
    required this.work,
    required this.rootNodes,
  });

  @override
  ConsumerState<FileNodeBrowser> createState() => _FileNodeBrowserState();
}

class _FileNodeBrowserState extends ConsumerState<FileNodeBrowser> {
  bool _historyChecked = false;

  @override
  void initState() {
    super.initState();
    _checkHistoryOnce();
  }

  Future<void> _checkHistoryOnce() async {
    final playerState = ref.read(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);
    final history = await playerController.checkHistoryForWork(widget.work);

    if (!_historyChecked &&
        mounted &&
        history != null &&
        history.lastTrackId != playerState.currentTrack?.id) {
      _historyChecked = true;
      if (!mounted) return;

      KikoenaiToast.show(
        message: '检测到上次播放: ${history.currentTrackTitle}',
        context: context,
        backgroundColor: Colors.blueGrey,
        icon: Icons.history,
        action: SnackBarAction(
          label: '恢复',
          textColor: Colors.amberAccent,
          onPressed: () {
            playerController.restoreHistory(
              widget.rootNodes,
              widget.work,
              history,
            );
          },
        ),
      );
    }
  }

  /// [核心逻辑] 批量替换本地路径
  /// 接收原始节点列表和下载记录 Map，返回 URL 已替换为本地路径的新列表
  Future<List<FileNode>> _resolveLocalPathNodes(
      List<FileNode> nodes, Map<String, TaskRecord> taskMap) async {
    if (taskMap.isEmpty) return nodes;

    return await Future.wait(nodes.map((node) async {
      // 检查该节点是否有对应的下载记录 (使用 hash 匹配 taskId)
      if (taskMap.containsKey(node.hash)) {
        final task = taskMap[node.hash]!.task;
        // 获取本地绝对路径 (异步操作)
        final String localPath = await task.filePath();
        // 创建新对象，替换 URL
        return node.copyWith(mediaStreamUrl: localPath);
      }
      return node;
    }));
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = fileBrowserProvider(widget.work.id.toString());
    final breadcrumb = ref.watch(browserProvider);
    final browserNotifier = ref.read(browserProvider.notifier);

    final currentNodes = browserNotifier.getCurrentNodes(widget.rootNodes);
    final bool isRoot = breadcrumb.isEmpty;

    final isCompleteDownloadFileList = ref.watch(completedTasksProvider);
    // 使用 valueOrNull 安全解包，如果还在加载中则为空列表
    final taskList = isCompleteDownloadFileList;
    final Map<String, TaskRecord> downloadedTaskMap = {
      for (var record in taskList) record.task.taskId: record
    };

    return PopScope(
      canPop: isRoot,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        browserNotifier.goBack();
      },
      child: SliverMainAxisGroup(
        slivers: [
          // 1. 吸顶 Header
          SliverPersistentHeader(
            pinned: true,
            delegate: BreadcrumbHeaderDelegate(
              work: widget.work,
              rootNodes: widget.rootNodes,
              breadcrumb: breadcrumb,
              onRootTap: () => browserNotifier.jumpToBreadcrumbIndex(-1),
              onCrumbTap: (index) =>
                  browserNotifier.jumpToBreadcrumbIndex(index),
              // Header 只需要 ID 集合用于弹窗禁用
              downloadedIds: downloadedTaskMap.keys.toSet(),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1)),

          // 3. 列表内容
          if (currentNodes.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text("该目录为空")),
            )
          else
            SliverList.builder(
              itemCount: currentNodes.length,
              itemBuilder: (_, index) {
                final node = currentNodes[index];
                // 判断是否已下载
                final bool isDownloaded =
                downloadedTaskMap.containsKey(node.hash);
                return _buildFileTile(
                  context,
                  node,
                  currentNodes,
                  browserNotifier,
                  isDownloaded,
                  downloadedTaskMap, // 传入 Map 供 onTap 使用
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildFileTile(
      BuildContext context,
      FileNode node,
      List<FileNode> currentNodes,
      FileBrowserNotifier notifier,
      bool isDownloaded,
      Map<String, TaskRecord> downloadedTaskMap,
      ) {
    final tile = ListTile(
      leading: Icon(_iconByType(node)),
      title: Text(
        node.title,
        style: TextStyle(
          // 已下载的文件稍微加深一点颜色
          color: isDownloaded ? Colors.black87 : null,
          fontWeight: isDownloaded ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        "${node.isAudio ? "时长:" : "类型："}"
            "${node.isAudio ? TimeFormatter.formatSeconds(node.duration?.toInt() ?? 0) : node.type.name}",
      ),
      // --- UI 标识：本地标签 ---
      trailing: isDownloaded
          ? Container(
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
            Text("本地",
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      )
          : null,
      onTap: () async {
        // [关键] onTap 变成 async
        if (node.isFolder) {
          notifier.enterFolder(node);
        } else if (node.isImage) {
          _handleImagePreview(context, node, currentNodes);
        } else if (node.isText) {
          _handleTextPreview(context, node);
        } else {
          // --- 播放逻辑：自动替换本地路径 ---
          final playerController = ref.read(playerControllerProvider.notifier);
          final List<FileNode> processedList =
          await _resolveLocalPathNodes(currentNodes, downloadedTaskMap);
          // 2. 找到当前点击的目标节点（使用处理后的列表，因为它包含本地路径）
          final FileNode targetNode = processedList.firstWhere(
                (n) => n.hash == node.hash,
            orElse: () => node,
          );

          // 3. 传递给播放器
          playerController.handleFileTap(targetNode, processedList,
              work: widget.work);
          // 字幕文件列表处理 (视情况而定，这里暂传原始列表)
          playerController.addSubTitleFileList(widget.rootNodes);
        }
      },
    );

    if (node.isAudio) {
      return ContextMenuWrapper(
        items: const [
          PopupMenuItem(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('添加到播放列表')
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == 'add') {
            FileNode nodeToAdd = node;
            if (downloadedTaskMap.containsKey(node.hash)) {
              final localPath = await downloadedTaskMap[node.hash]!.task.filePath();
              nodeToAdd = node.copyWith(mediaStreamUrl: localPath);
            }
            ref
                .read(playerControllerProvider.notifier)
                .addSingleInQueue(nodeToAdd, widget.work);
            KikoenaiToast.success("已添加到播放列表");
          }
        },
        child: tile,
      );
    }
    return tile;
  }

  void _handleImagePreview(
      BuildContext context, FileNode node, List<FileNode> currentNodes) {
    final imageNodes = currentNodes.where((n) => n.isImage).toList();
    final imageUrls = imageNodes
        .map((n) => n.mediaStreamUrl ?? "")
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
          url: node.mediaStreamUrl ?? "",
          title: node.title,
        ),
      ),
    );
  }

  IconData _iconByType(FileNode node) {
    if (node.isAudio) return Icons.audiotrack;
    if (node.isImage) return Icons.image;
    if (node.isText) return Icons.text_snippet;
    return Icons.folder;
  }
}

class BreadcrumbHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<FileNode> breadcrumb;
  final List<FileNode> rootNodes;
  final VoidCallback onRootTap;
  final Work work;
  final Set<String> downloadedIds;
  final void Function(int index) onCrumbTap;

  BreadcrumbHeaderDelegate({
    required this.work,
    required this.rootNodes,
    required this.downloadedIds,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _BreadcrumbHeader(
      work: work,
      breadcrumb: breadcrumb,
      rootNodes: rootNodes,
      onRootTap: onRootTap,
      onCrumbTap: onCrumbTap,
      downloadedIds: downloadedIds,
    );
  }

  @override
  double get maxExtent => 72;
  @override
  double get minExtent => 72;
  @override
  bool shouldRebuild(covariant BreadcrumbHeaderDelegate oldDelegate) => true;
}

class _BreadcrumbHeader extends ConsumerWidget {
  final Set<String> downloadedIds;
  final List<FileNode> breadcrumb;
  final List<FileNode> rootNodes;
  final VoidCallback onRootTap;
  final Work work;
  final void Function(int index) onCrumbTap;

  const _BreadcrumbHeader({
    required this.downloadedIds,
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);
    final ScrollController scrollController = ScrollController();
    final DownloadService downloadService = DownloadService.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onRootTap,
                    child: const Text('根目录',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  for (int i = 0; i < breadcrumb.length; i++) ...[
                    const Icon(Icons.chevron_right, size: 20),
                    GestureDetector(
                      onTap: () => onCrumbTap(i),
                      child: Text(
                        breadcrumb[i].title,
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            iconSize: 18,
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
            icon: Icon(Icons.library_music,
                color: isDark ? Colors.white70 : Colors.grey),
            onPressed: () {
              FileTreeDialogExtension.showFileTree(
                context: context,
                roots: rootNodes,
                disabledIds: downloadedIds,
                onAddToQueue: (List<FileNode> selectedFiles) {
                  final audioFiles =
                  selectedFiles.where((f) => f.isAudio).toList();
                  ref
                      .read(playerControllerProvider.notifier)
                      .addMultiInQueue(audioFiles, work);
                  KikoenaiToast.success("成功添加该列表");
                  KikoenaiDialog.dismiss();
                },
                onDownload: (List<FileNode> selectedFiles) {
                  downloadService.enqueueBatch(
                      selectedFiles: selectedFiles,
                      rootNodes: rootNodes,
                      title: work.title ?? '未知作品',
                      metaData: work.toJson()); // 确保 metaData 传入 Map
                },
              );
            },
          ),
        ],
      ),
    );
  }
}