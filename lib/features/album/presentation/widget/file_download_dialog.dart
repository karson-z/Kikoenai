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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.watch(fileSelectionProvider);
    final notifier = ref.read(fileSelectionProvider.notifier);
    final selectedCount = notifier.count;
    final musicCount = notifier.musicCount;
    final totalSizeStr = notifier.totalSizeStr;
    final bool? rootCheckboxState = notifier.getRootState(widget.roots);

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
                      // 注意：全选逻辑中，Notifier 最好也能内部处理 disabledIds 的过滤
                      // 或者在这里仅作为 UI 层的全选，实际操作由 Notifier 处理
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
                  TextButton.icon(
                    onPressed: musicCount == 0
                        ? null
                        : () => widget.onAddToQueue(notifier.selectedList),
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
                      onPressed: selectedCount == 0
                          ? null
                          : () {
                        // 提交下载前，可以在这里做最后一道过滤，剔除掉 disabledIds 中的文件
                        // 但通常 UI 上禁止选中就足够了
                        widget.onDownload(notifier.selectedList);
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

    final bool isDisabled = !node.isFolder && (widget.disabledIds?.contains(node.hash) ?? false);

    final bool? checkboxState = notifier.getNodeState(node);

    Widget buildCheckbox() {
      if (isDisabled) {
        return const Padding(
          padding: EdgeInsets.all(12.0), // 保持和 Checkbox 占据空间一致，防止对齐错乱
          child: Icon(
              Icons.check_circle_outline, // 使用空心圆勾选，表示"已完成"
              size: 20,
              color: Colors.grey
          ),
        );
      }

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
        // --- 【修改点 3】 如果已下载，禁用点击事件 ---
        onTap: isDisabled ? null : () => notifier.toggleNode(node),
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
                    Text(
                      node.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        // 可选：如果是已下载，文字也变灰
                        color: isDisabled ? Colors.grey : null,
                        decoration: isDisabled ? TextDecoration.lineThrough : null, // 可选：添加删除线表示不可选
                        decorationColor: Colors.grey.shade300,
                      ),
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