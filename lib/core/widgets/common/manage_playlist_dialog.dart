import 'package:flutter/material.dart';
import 'package:kikoenai/core/utils/data/other.dart';

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

    ref.watch(fileSelectionProvider);
    final notifier = ref.read(fileSelectionProvider.notifier);

    final selectedList = notifier.selectedList;
    final selectedCount = notifier.count;
    final musicCount = notifier.musicCount;
    final totalSizeStr = notifier.totalSizeStr;
    final bool? rootCheckboxState = notifier.getRootState(widget.roots);

    final bool canDownload =
    selectedList.any((node) => !node.isFolder && !_isDownloaded(node));

    // 移除原有的 Dialog，直接返回 Container
    return Container(
      // 设置高度为全屏高度
      height: mediaQuery.size.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        // BottomSheet 通常只需要顶部圆角
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      // 增加 SafeArea 防止内容被刘海屏或底部导航条遮挡
      child: SafeArea(
        child: Column(
          children: [
            // 顶部增加一个拖拽指示条 (可选，增加 BottomSheet 的视觉暗示)
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
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 12, 12),
              child: Row(
                children: [
                  Checkbox(
                    tristate: true,
                    value: rootCheckboxState,
                    onChanged: (_) {
                      notifier.toggleSelectAll(widget.roots);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rootCheckboxState != null && rootCheckboxState
                            ? '取消全选'
                            : '全选文件',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: widget.roots.isEmpty
                  ? const Center(child: Text("暂无文件数据"))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicWidth(
                  child: SizedBox(
                    // 将最小宽度改为屏幕宽度，而不是写死的 500
                    width: mediaQuery.size.width,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.roots.length,
                      itemBuilder: (context, index) {
                        return _buildNodeItem(
                            widget.roots[index], 0, notifier);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
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

  Widget _buildNodeItem(
      FileNode node, int level, FileSelectionNotifier notifier) {
    final double indent = level * 20.0;
    final bool isDownloaded = _isDownloaded(node);
    final bool? checkboxState = notifier.getNodeState(node);

    Widget buildCheckbox() {
      return Checkbox(
        tristate: true,
        value: checkboxState,
        onChanged: (_) => notifier.toggleNode(node),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      );
    }

    if (node.isFolder) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(node.hash ?? node.title),
          tilePadding: EdgeInsets.only(left: 8 + indent, right: 16),
          leading: buildCheckbox(),
          title: InkWell(
            child: Row(
              children: [
                _getIconForNode(node),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          children: node.children
              ?.map((child) => _buildNodeItem(child, level + 1, notifier))
              .toList() ??
              [],
        ),
      );
    } else {
      return InkWell(
        onTap: () => notifier.toggleNode(node),
        child: Padding(
          padding:
          EdgeInsets.only(left: 8 + indent, right: 16, top: 10, bottom: 10),
          child: Row(
            children: [
              buildCheckbox(),
              const SizedBox(width: 8),
              _getIconForNode(node),
              const SizedBox(width: 8),
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
                              fontSize: 14,
                              color: isDownloaded ? Colors.grey.shade600 : null,
                            ),
                          ),
                        ),
                        if (isDownloaded) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle,
                              size: 14,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.7)),
                          const SizedBox(width: 2),
                          Text("已下载",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.7))),
                        ],
                      ],
                    ),
                    if (node.size != null)
                      Text(
                        OtherUtil.formatBytes(node.size ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
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
      // 解除 Material 规范中的默认最大宽度限制
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return FileTreeDialogContent(
          roots: roots,
          disabledIds: disabledIds,
          onDownload: onDownload,
          onAddToQueue: onAddToQueue,
        );
      },
    );
  }
}