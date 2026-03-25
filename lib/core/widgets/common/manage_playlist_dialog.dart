import 'package:flutter/material.dart';
import 'package:kikoenai/core/utils/data/other.dart';

import '../bread_crumb_bar/file_bread_crumb_bar.dart';
import 'back_button_interceptor.dart';
import 'kikoenai_dialog.dart';
import '../../model/file_node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/album/presentation/viewmodel/provider/file_manage_provider.dart';

class FileTreeDialogContent extends ConsumerStatefulWidget {
  final List<FileNode> roots;
  final Set<String>? disabledIds;
  final Function(List<FileNode>) onDownload;
  final Function(List<FileNode>) onAddToQueue;

  const FileTreeDialogContent({
    super.key,
    this.disabledIds,
    required this.roots,
    required this.onDownload,
    required this.onAddToQueue,
  });

  @override
  ConsumerState<FileTreeDialogContent> createState() =>
      _FileTreeDialogContentState();
}

class _FileTreeDialogContentState extends ConsumerState<FileTreeDialogContent> {
  // 局部导航路径状态
  List<FileNode> _currentPath = [];

  // 获取当前层级应该显示的节点列表
  List<FileNode> get _currentNodes {
    if (_currentPath.isEmpty) {
      return widget.roots;
    }
    return _currentPath.last.children ?? [];
  }

  Icon _getIconForNode(FileNode node) {
    if (node.isFolder) return const Icon(Icons.folder, color: Colors.amber);
    if (node.isAudio) {
      return const Icon(Icons.audiotrack, color: Colors.purpleAccent);
    }
    if (node.isImage) return const Icon(Icons.image, color: Colors.blue);
    if (node.isVideo) {
      return const Icon(Icons.videocam, color: Colors.redAccent);
    }
    if (node.isText) return const Icon(Icons.description, color: Colors.grey);
    return const Icon(Icons.insert_drive_file, color: Colors.blueGrey);
  }

  bool _isDownloaded(FileNode node) {
    if (node.isFolder) return false;
    return widget.disabledIds?.contains(node.hash) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // UI 渲染依然可以通过 ref.read/watch 获取所需的数据
    final selectionState = ref.watch(fileSelectionProvider);
    final notifier = ref.read(fileSelectionProvider.notifier);
    final selectedList = notifier.selectedList;
    final selectedCount = notifier.count;
    final musicCount = notifier.musicCount;
    final totalSizeStr = notifier.totalSizeStr;

    // 全选状态针对当前显示的层级
    final bool? currentLayerCheckboxState = notifier.getRootState(_currentNodes);

    final bool canDownload =
    selectedList.any((node) => !node.isFolder && !_isDownloaded(node));

    return Container(
      height: mediaQuery.size.height * 0.95,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 操作栏
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 12, 12),
              child: Row(
                children: [
                  Checkbox(
                    tristate: true,
                    value: currentLayerCheckboxState,
                    onChanged: (_) {
                      // 【修复】点击交互时，实时读取最新的 notifier
                      ref.read(fileSelectionProvider.notifier).toggleSelectAll(_currentNodes);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLayerCheckboxState != null && currentLayerCheckboxState
                            ? '取消全选(当前层)'
                            : '全选(当前层)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (selectedCount > 0)
                        Text(
                          '已选: $totalSizeStr',
                          style: TextStyle(
                              fontSize: 12, color: theme.primaryColor),
                        ),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: musicCount == 0
                        ? null
                        : () => widget.onAddToQueue(selectedList),
                    icon: const Icon(Icons.queue_music, size: 20),
                    label: const Text('加入队列'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                      musicCount == 0 ? Colors.grey : theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // 面包屑导航栏：绑定局部状态 _currentPath
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: BreadcrumbBar(
                paths: _currentPath.map((node) => node.title).toList(),
                // 点击根目录，清空路径返回顶层
                onHomeTap: () {
                  if (_currentPath.isNotEmpty) {
                    setState(() => _currentPath.clear());
                  }
                },
                // 点击具体层级，截断到该层级
                onPathTap: (index) {
                  if (index < _currentPath.length - 1) {
                    setState(() {
                      _currentPath = _currentPath.sublist(0, index + 1);
                    });
                  }
                },
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                borderColor: Colors.transparent, // 如果想隐藏边框
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // 列表区域
            Expanded(
              child: _currentNodes.isEmpty
                  ? const Center(child: Text("空文件夹"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _currentNodes.length,
                itemBuilder: (context, index) {
                  // 【修复】移除了 notifier 参数传递
                  return _buildNodeItem(_currentNodes[index]);
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // 底部按钮区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => KikoenaiDialog.dismiss(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !canDownload
                          ? null
                          : () {
                        final filesToDownload = selectedList
                            .where((node) =>
                        !node.isFolder && !_isDownloaded(node))
                            .toList();

                        if (filesToDownload.isNotEmpty) {
                          widget.onDownload(filesToDownload);
                        }
                        KikoenaiDialog.dismiss();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text(
                        '下载',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeItem(FileNode node) {
    final bool isDownloaded = _isDownloaded(node);
    final bool? checkboxState = ref.read(fileSelectionProvider.notifier).getNodeState(node);

    Widget buildCheckbox() {
      return Checkbox(
        tristate: true,
        value: checkboxState,
        onChanged: (_) {
          // 【修复】交互时实时读取 notifier
          ref.read(fileSelectionProvider.notifier).toggleNode(node);
        },
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      );
    }

    return InkWell(
      onTap: () {
        if (node.isFolder) {
          // 如果是文件夹，点击进入下一级
          setState(() {
            _currentPath.add(node);
          });
        } else {
          // 【修复】交互时实时读取 notifier
          ref.read(fileSelectionProvider.notifier).toggleNode(node);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            buildCheckbox(),
            const SizedBox(width: 8),
            _getIconForNode(node),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          node.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: node.isFolder ? FontWeight.w500 : FontWeight.normal,
                            color: isDownloaded ? Colors.grey.shade600 : null,
                          ),
                        ),
                      ),
                      if (isDownloaded && !node.isFolder) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle,
                            size: 14,
                            color: Theme.of(context).primaryColor.withOpacity(0.7)),
                        const SizedBox(width: 2),
                        Text("已下载",
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor.withOpacity(0.7))),
                      ],
                    ],
                  ),
                  if (!node.isFolder && node.size != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        OtherUtil.formatBytes(node.size ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  if (node.isFolder)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${node.children?.length ?? 0} 项',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
            // 如果是文件夹，在最右侧显示一个向右的箭头提示可以点击进入
            if (node.isFolder)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

extension FileTreeDialogExtension on KikoenaiDialog {
  static Future<void> showFileTree({
    BuildContext? context,
    required List<FileNode> roots,
    Set<String>? disabledIds,
    required Function(List<FileNode>) onDownload,
    required Function(List<FileNode>) onAddToQueue,
  }) async {
    await KikoenaiDialog.showBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return BackButtonPriorityWrapper(
          zIndex: 100,
          name: 'FileTreeBottomSheet',
          child: FileTreeDialogContent(
            roots: roots,
            disabledIds: disabledIds,
            onDownload: onDownload,
            onAddToQueue: onAddToQueue,
          ),
        );
      },
    );
  }
}