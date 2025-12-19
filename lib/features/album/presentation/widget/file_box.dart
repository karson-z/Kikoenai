import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/core/widgets/layout/app_dropdown_sheet.dart';
import 'package:kikoenai/core/widgets/menu/menu.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import '../../../../core/theme/theme_view_model.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../../core/widgets/player/provider/player_controller_provider.dart';
import '../../../../core/widgets/text_preview/text_preview_page.dart';
import '../../data/model/file_node.dart';
import '../viewmodel/provider/audio_manage_provider.dart';

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
      AppToast.show(
        context,
        '检测到上次播放: ${history.currentTrackTitle}',
        action: SnackBarAction(
          label: '恢复',
          onPressed: () {
            playerController.restoreHistory(
              widget.rootNodes,
              widget.work,
              history,
            );
          },
        ),
        backgroundColor: Colors.blueGrey,
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
    // 判断是否在根目录
    final bool isRoot = _breadcrumb.isEmpty;

    // 使用 PopScope 拦截返回事件
    return PopScope(
      // 如果在根目录 (isRoot为true)，允许系统直接退出页面 (canPop: true)
      // 如果在子目录 (isRoot为false)，禁止系统直接退出 (canPop: false)，由我们在 onPopInvoked 中手动处理
      canPop: isRoot,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          // 如果系统已经处理了返回（即 canPop 为 true 时），我们什么都不做
          return;
        }
        // 如果系统被拦截了（canPop 为 false），说明我们在子目录，执行返回上一级逻辑
        _handleBack();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: BreadcrumbHeaderDelegate(
                work: widget.work,
                rootNodes: widget.rootNodes,
                breadcrumb: _breadcrumb,
                onRootTap: () => _goToBreadcrumbIndex(-1),
                onCrumbTap: _goToBreadcrumbIndex,
              ),
            ),

            const SliverToBoxAdapter(child: Divider(height: 1)),

            if (_currentNodes.isEmpty)
              const SliverFillRemaining(
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
                    // 修改：如果是文件夹，点击进入
                    onTap: () {
                      if (node.isFolder) {
                        _enterFolder(node);
                      } else if (node.isText) {
                        // 跳转到文本预览页面
                        // 请确保 node 对象中有 url 字段，或者根据你的 FileNode 定义获取下载链接
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TextPreviewPage(
                              url: node.mediaStreamUrl ?? "", // 这里填入文件的实际下载链接
                              title: node.title,
                            ),
                          ),
                        );
                      } else {
                        // 音频播放逻辑
                        final playerController = ref.read(playerControllerProvider.notifier);
                        playerController.handleFileTap(node,_currentNodes,work: widget.work);
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
                            playController.addSubTitleFileList(widget.rootNodes);
                            playController.addSingleInQueue(node, widget.work);
                        }
                      },
                    );
                  } else {
                    return tile;
                  }
                },
              ),
          ],
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
class _BreadcrumbHeader extends ConsumerWidget {
  final List<FileNode> breadcrumb;
  final List<FileNode> rootNodes;
  final VoidCallback onRootTap;
  final Work work;
  final void Function(int index) onCrumbTap;

  const _BreadcrumbHeader({
    Key? key,
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
  }) : super(key: key);

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
        // 滚动到最右端（即最后一个节点）
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
          // 滚动面包屑
          Expanded(
            child: SingleChildScrollView(
              // 💡 3. 将 ScrollController 赋给 SingleChildScrollView
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

          // ... (管理按钮部分保持不变)
          IconButton(
            iconSize: 18,
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
            icon: Icon(
              Icons.library_music,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            onPressed: () {
              // 1. 先计算出所有的音频文件，供后面使用
              final audioFiles = _collectAllAudioFiles(rootNodes);

              CustomDropdownSheet.show(
                isDark: isDark,
                context: context,
                title: '管理音频文件',
                maxHeight: 500,
                onClosed: () {
                  ref.read(audioManageProvider.notifier).reset();
                },

                // --- 修改了这里 actionButtons ---
                actionButtons: [
                  Consumer(
                    builder: (_, ref, __) {
                      final state = ref.watch(audioManageProvider);
                      final notifier = ref.read(audioManageProvider.notifier);

                      // 判断当前是否已经全选
                      final isAllSelected = state.selected.length == audioFiles.length && audioFiles.isNotEmpty;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 只有在多选模式下才显示全选/取消全选按钮
                          if (state.multiSelectMode)
                            IconButton(
                              tooltip: isAllSelected ? "取消全选" : "全选",
                              icon: Icon(
                                // 如果全选了显示清除图标，否则显示全选图标
                                isAllSelected ? Icons.deselect : Icons.select_all,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                if (isAllSelected) {
                                  notifier.clearSelection();
                                } else {
                                  notifier.selectAll(audioFiles);
                                }
                              },
                            ),

                          // 模式切换/确认播放按钮
                          IconButton(
                            tooltip: state.multiSelectMode ? "加入队列" : "批量管理",
                            icon: Icon(
                              state.multiSelectMode ? Icons.play_arrow : Icons.edit, // 图标改得更直观一点
                              color: state.multiSelectMode ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              if (state.multiSelectMode) {
                                // 确认播放逻辑
                                if (state.selected.isNotEmpty) {
                                  final playController = ref.read(playerControllerProvider.notifier);
                                  playController.addSubTitleFileList(rootNodes);
                                  playController.addMultiInQueue(state.selected.toList(), work);
                                  Navigator.of(context).pop();
                                }
                              } else {
                                // 进入多选模式
                                notifier.toggleMultiSelect();
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],

                contentBuilder: (modalContext) {
                  return Consumer(
                    builder: (_, ref, __) {
                      final state = ref.watch(audioManageProvider);

                      if (audioFiles.isEmpty) {
                        return const Center(child: Text("没有音频文件"));
                      }

                      return ListView.builder(
                        itemCount: audioFiles.length,
                        itemBuilder: (context, index) {
                          final file = audioFiles[index];
                          // 检查是否包含
                          final isSelected = state.selected.contains(file);

                          if (state.multiSelectMode) {
                            return CheckboxListTile(
                              title: Text(
                                file.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                "音频类型: ${file.title.substring(file.title.length - 4)}",
                              ),
                              value: isSelected,
                              onChanged: (checked) {
                                // 这里的逻辑现在配合上面修正后的 Notifier 应该能正常工作了
                                if (checked == true) {
                                  ref.read(audioManageProvider.notifier).select(file);
                                } else {
                                  ref.read(audioManageProvider.notifier).unselect(file);
                                }
                              },
                            );
                          }

                          // 非多选模式下的普通列表项
                          return ListTile(
                            title: Text(
                              file.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              "时长: ${TimeFormatter.formatSeconds(file.duration?.toInt() ?? 0)}",
                            ),
                            onTap: () {
                              ref.read(playerControllerProvider.notifier)
                                  .addSingleInQueue(file, work);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// pinned header delegate
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
  double get maxExtent => 88;

  @override
  double get minExtent => 88;
}
