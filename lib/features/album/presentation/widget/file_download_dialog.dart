import 'package:flutter/material.dart';
import 'package:kikoenai/core/utils/data/other.dart';

import '../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../data/model/file_node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/provider/file_manage_provider.dart';

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
  ConsumerState<FileTreeDialogContent> createState() => _FileTreeDialogContentState();
}

class _FileTreeDialogContentState extends ConsumerState<FileTreeDialogContent> {

  Icon _getIconForNode(FileNode node) {
    if (node.isFolder) return const Icon(Icons.folder, color: Colors.amber);
    if (node.isAudio) return const Icon(Icons.audiotrack, color: Colors.purpleAccent);
    if (node.isImage) return const Icon(Icons.image, color: Colors.blue);
    if (node.isVideo) return const Icon(Icons.videocam, color: Colors.redAccent);
    if (node.isText) return const Icon(Icons.description, color: Colors.grey);
    return const Icon(Icons.insert_drive_file, color: Colors.blueGrey);
  }

  /// 判断文件是否已下载
  bool _isDownloaded(FileNode node) {
    if (node.isFolder) return false;
    return widget.disabledIds?.contains(node.hash) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.watch(fileSelectionProvider);
    final notifier = ref.read(fileSelectionProvider.notifier);

    // 获取当前选中的所有节点（包含文件夹和文件）
    final selectedList = notifier.selectedList;
    final selectedCount = notifier.count;
    final musicCount = notifier.musicCount;
    final totalSizeStr = notifier.totalSizeStr;
    final bool? rootCheckboxState = notifier.getRootState(widget.roots);

    // 允许下载的条件：
    // 1. 至少选中了一个文件 (selectedCount > 0)
    // 2. 选中的文件中，至少有一个是"未下载"状态
    final bool canDownload = selectedList.any((node) =>
    !node.isFolder && !_isDownloaded(node)
    );

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 500,
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 16, 12, 12),
              child: Row(
                children: [
                  Checkbox(
                    tristate: true,
                    value: rootCheckboxState,
                    onChanged: (_) {
                      notifier.toggleSelectAll(widget.roots);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rootCheckboxState != null && rootCheckboxState ? '取消全选' : '全选文件',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (selectedCount > 0)
                        Text(
                          '已选: $totalSizeStr',
                          style: TextStyle(fontSize: 12, color: theme.primaryColor),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // 加入队列按钮：只要选中有音乐文件，无论是否下载，都允许加入队列
                  TextButton.icon(
                    onPressed: musicCount == 0
                        ? null
                        : () => widget.onAddToQueue(selectedList),
                    icon: const Icon(Icons.queue_music, size: 20),
                    label: const Text('加入队列'),
                    style: TextButton.styleFrom(
                      foregroundColor: musicCount == 0 ? Colors.grey : theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            Expanded(
              child: widget.roots.isEmpty
                  ? const Center(child: Text("暂无文件数据"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.roots.length,
                itemBuilder: (context, index) {
                  return _buildNodeItem(widget.roots[index], 0, notifier);
                },
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      // 下载按钮状态控制：
                      // 如果选中的全部都是已下载文件 (canDownload == false)，则禁用按钮
                      onPressed: !canDownload
                          ? null
                          : () {
                        // 提交时，只传递"未下载"的文件给下载器，避免重复下载
                        // 或者根据需求传递所有选中文件，由后端去重
                        final filesToDownload = selectedList.where((node) =>
                        !node.isFolder && !_isDownloaded(node)
                        ).toList();

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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildNodeItem(FileNode node, int level, FileSelectionNotifier notifier) {
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          children: node.children?.map((child) => _buildNodeItem(child, level + 1, notifier)).toList() ?? [],
        ),
      );
    } else {
      return InkWell(
        // 恢复点击事件，允许 toggleNode
        onTap: () => notifier.toggleNode(node),
        child: Padding(
          padding: EdgeInsets.only(left: 8 + indent, right: 16, top: 10, bottom: 10),
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
                        // 视觉提示：如果已下载，显示一个小勾选图标，提示用户状态
                        if (isDownloaded) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle, size: 14, color: Theme.of(context).primaryColor.withOpacity(0.7)),
                          const SizedBox(width: 2),
                          Text("已下载", style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor.withOpacity(0.7))),
                        ],
                      ],
                    ),
                    if (node.size != null)
                      Text(
                        OtherUtil.formatBytes(node.size ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
    await KikoenaiDialog.show(
      context: context,
      clickMaskDismiss: true,
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