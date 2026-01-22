import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/core/widgets/layout/app_dropdown_sheet.dart';
import 'package:kikoenai/core/widgets/menu/menu.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import '../../../../core/theme/theme_view_model.dart';
import '../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../../../core/widgets/image_box/image_view.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../../core/widgets/player/provider/player_controller_provider.dart';
import '../../../../core/widgets/text_preview/text_preview_page.dart';
import '../../data/model/file_node.dart';
import '../viewmodel/provider/audio_manage_provider.dart';
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
  final List<FileNode> _breadcrumb = [];
  bool _historyChecked = false;

  @override
  void initState() {
    super.initState();
    _checkHistoryOnce();
  }

  void _handleBack() {
    setState(() {
      if (_breadcrumb.isNotEmpty) {
        _breadcrumb.removeLast();
      }
    });
  }

  Future<void> _checkHistoryOnce() async {
    final playerState = ref.read(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);
    final history = await playerController.checkHistoryForWork(widget.work);

    if (!_historyChecked && mounted && history != null && history.lastTrackId != playerState.currentTrack?.id) {
      _historyChecked = true;

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

  List<FileNode> get _currentNodes =>
      _breadcrumb.isEmpty ? widget.rootNodes : _breadcrumb.last.children ?? [];

  void _enterFolder(FileNode folder) {
    setState(() => _breadcrumb.add(folder));
  }

  void _goToBreadcrumbIndex(int index) {
    setState(() {
      if (index == -1) {
        _breadcrumb.clear();
      } else {
        _breadcrumb.removeRange(index + 1, _breadcrumb.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isRoot = _breadcrumb.isEmpty;

    return PopScope(
      canPop: isRoot,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBack();
      },
      child: SliverMainAxisGroup(
        slivers: [
          // 1. 吸顶 Header
          SliverPersistentHeader(
            pinned: true, // 开启吸顶
            delegate: BreadcrumbHeaderDelegate(
              work: widget.work,
              rootNodes: widget.rootNodes,
              breadcrumb: _breadcrumb,
              onRootTap: () => _goToBreadcrumbIndex(-1),
              onCrumbTap: _goToBreadcrumbIndex,
            ),
          ),

          // 2. 分割线
          const SliverToBoxAdapter(child: Divider(height: 1)),

          // 3. 列表内容
          if (_currentNodes.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text("该目录为空")),
            )
          else
            SliverList.builder(
              itemCount: _currentNodes.length,
              itemBuilder: (_, index) {
                final node = _currentNodes[index];
                final tile = ListTile(
                  leading: Icon(_iconByType(node)),
                  title: Text(node.title),
                  subtitle: Text(
                    "${node.isAudio ? "时长:" : "类型："}"
                        "${node.isAudio ? TimeFormatter.formatSeconds(node.duration?.toInt() ?? 0) : node.type.name}",
                  ),
                  onTap: () {
                    if (node.isFolder) {
                      _enterFolder(node);
                    } else if (node.isImage) {
                      // --- 新增图片预览逻辑 ---

                      // 1. 筛选出当前层级下所有的图片节点
                      final imageNodes = _currentNodes.where((n) => n.isImage).toList();

                      // 2. 提取 URL 列表 (假设 URL 存在 mediaStreamUrl 字段中)
                      final imageUrls = imageNodes
                          .map((n) => n.mediaStreamUrl ?? "")
                          .where((url) => url.isNotEmpty) // 安全过滤空链接
                          .toList();
                      final initialIndex = imageNodes.indexOf(node);
                      if (imageUrls.isNotEmpty && initialIndex != -1) {
                        context.push(
                          AppRoutes.imageView, // 对应上面定义的 path
                          extra: {
                            'urls': imageUrls,
                            'index': initialIndex,
                          },
                        );
                      }

                    } else if (node.isText) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TextPreviewPage(
                            url: node.mediaStreamUrl ?? "",
                            title: node.title,
                          ),
                        ),
                      );
                    } else {
                      // 处理音频或其他媒体
                      final playerController = ref.read(playerControllerProvider.notifier);
                      playerController.handleFileTap(node, _currentNodes, work: widget.work);
                      playerController.addSubTitleFileList(widget.rootNodes);
                    }
                  },
                );

                if (node.isAudio) {
                  return ContextMenuWrapper(
                    items: [
                      PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: const [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('添加到播放列表'),
                          ],
                        ),
                      ),
                    ],
                    child: tile,
                    onSelected: (value) {
                      debugPrint('Audio file ${node.toJson()} selected: $value');
                      switch (value) {
                        case 'add':
                          final playController = ref.read(playerControllerProvider.notifier);
                          // playController.addSubTitleFileList(widget.rootNodes);
                          playController.addSingleInQueue(node, widget.work);
                      }
                    },
                  );
                } else {
                  return tile;
                }
              },
            ),

          // 底部垫高，防止被播放条遮挡
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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
class _BreadcrumbHeader extends ConsumerWidget {
  final List<FileNode> breadcrumb;
  final List<FileNode> rootNodes;
  final VoidCallback onRootTap;
  final Work work;
  final void Function(int index) onCrumbTap;

  const _BreadcrumbHeader({
    super.key,
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
  });

  List<FileNode> _collectAllAudioFiles(List<FileNode> nodes) {
    final List<FileNode> audioFiles = [];
    for (var node in nodes) {
      if (node.isAudio) {
        audioFiles.add(node);
      } else if (node.isFolder && node.children != null) {
        audioFiles.addAll(_collectAllAudioFiles(node.children!));
      }
    }
    return audioFiles;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);
    final ScrollController scrollController = ScrollController();

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
                    child: const Text(
                      '根目录',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (int i = 0; i < breadcrumb.length; i++) ...[
                    const Icon(Icons.chevron_right, size: 20),
                    GestureDetector(
                      onTap: () => onCrumbTap(i),
                      child: Text(
                        breadcrumb[i].title,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
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
            icon: Icon(
              Icons.library_music,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            onPressed: () {
              FileTreeDialogExtension.showFileTree(
                context: context,
                roots: rootNodes,
                // 顶部“加入队列”按钮回调
                onAddToQueue: (List<FileNode> selectedFiles) {
                  // 过滤出音频文件加入播放器
                  final audioFiles = selectedFiles.where((f) => f.isAudio).toList();
                  ref.read(playerControllerProvider.notifier).addMultiInQueue(audioFiles,work);
                  // 提示用户
                  KikoenaiToast.success("成功添加该列表");
                  // 如果需要自动关闭弹窗：
                  KikoenaiDialog.dismiss();
                },
                // 底部“下载”按钮回调
                onDownload: (List<FileNode> selectedFiles) {
                  print("开始下载文件数: ${selectedFiles.length}");
                  // TODO 执行下载文件列表
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class BreadcrumbHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<FileNode> breadcrumb;
  final List<FileNode> rootNodes;
  final VoidCallback onRootTap;
  final Work work;
  final void Function(int index) onCrumbTap;

  BreadcrumbHeaderDelegate({
    required this.work,
    required this.rootNodes,
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
    );
  }

  @override
  bool shouldRebuild(covariant BreadcrumbHeaderDelegate oldDelegate) {
    return true;
  }

  @override
  double get maxExtent => 72; // 保留你原来的高度

  @override
  double get minExtent => 72; // 保留你原来的高度
}