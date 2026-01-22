import 'package:flutter/material.dart';
// 替换为你项目中 KikoenaiDialog 和 FileNode 的实际路径
import 'package:kikoenai/common/widgets/kikoenai_dialog.dart';
import 'package:kikoenai/features/file/data/model/file_node.dart';

// --- 弹窗内容组件 ---
class FileTreeDialogContent extends StatefulWidget {
  final List<FileNode> roots;
  final Function(List<FileNode>) onDownload;
  final Function(List<FileNode>) onAddToQueue;

  const FileTreeDialogContent({
    super.key,
    required this.roots,
    required this.onDownload,
    required this.onAddToQueue,
  });

  @override
  State<FileTreeDialogContent> createState() => _FileTreeDialogContentState();
}

class _FileTreeDialogContentState extends State<FileTreeDialogContent> {
  // 使用 Set 存储被选中的节点对象
  final Set<FileNode> _selectedNodes = {};

  // 获取所有选中的“叶子节点”（即实际文件，排除文件夹本身，视需求而定）
  // 如果下载时只需要文件，用这个方法；如果文件夹也要传，直接用 _selectedNodes.toList()
  List<FileNode> _getSelectedLeafNodes() {
    return _selectedNodes.where((node) => !node.isFolder).toList();
  }

  // 切换选中状态
  void _toggleSelection(FileNode node, bool? value) {
    setState(() {
      if (value == true) {
        _selectedNodes.add(node);
        // 如果是文件夹，递归选中所有子节点
        if (node.isFolder && node.children != null) {
          _selectAllChildren(node.children!, true);
        }
      } else {
        _selectedNodes.remove(node);
        // 如果是文件夹，递归取消选中所有子节点
        if (node.isFolder && node.children != null) {
          _selectAllChildren(node.children!, false);
        }
      }
    });
  }

  // 递归处理子节点
  void _selectAllChildren(List<FileNode> nodes, bool select) {
    for (var node in nodes) {
      if (select) {
        _selectedNodes.add(node);
      } else {
        _selectedNodes.remove(node);
      }
      if (node.children != null) {
        _selectAllChildren(node.children!, select);
      }
    }
  }

  // 获取对应类型的图标
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
    final selectedCount = _selectedNodes.length;
    // 计算仅文件的选中数量（用于显示在按钮上）
    final selectedFileCount = _getSelectedLeafNodes().length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // 限制最大宽度，适配平板或桌面端
      child: Container(
        height: 500, // 固定高度
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          children: [
            // --- 1. 头部区域 ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Text(
                    '选择文件',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // 加入队列按钮
                  TextButton.icon(
                    onPressed: selectedCount == 0
                        ? null
                        : () {
                      widget.onAddToQueue(_getSelectedLeafNodes());
                    },
                    icon: const Icon(Icons.queue_music, size: 20),
                    label: const Text('加入队列'),
                    style: TextButton.styleFrom(
                      // 没选中时颜色变淡
                      foregroundColor: selectedCount == 0 ? Colors.grey : theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // --- 2. 文件树列表区域 ---
            Expanded(
              child: widget.roots.isEmpty
                  ? const Center(child: Text("暂无文件数据"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.roots.length,
                itemBuilder: (context, index) {
                  return _buildNodeItem(widget.roots[index], 0);
                },
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // --- 3. 底部操作区域 ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 取消按钮
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
                  // 下载按钮
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedCount == 0
                          ? null
                          : () {
                        // 点击下载，返回选中的文件
                        widget.onDownload(_getSelectedLeafNodes());
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
                      child: Text(selectedCount > 0 ? '下载 ($selectedFileCount)' : '下载'),
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

  // 递归构建树节点
  Widget _buildNodeItem(FileNode node, int level) {
    final double indent = level * 20.0; // 缩进宽度

    // 如果是文件夹，使用 ExpansionTile
    if (node.isFolder) {
      return Theme(
        // 消除 ExpansionTile 上下的边框线
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // 使用 Key 保持展开状态，如果有 hash 用 hash，没有用 title
          key: PageStorageKey(node.hash ?? node.title),
          tilePadding: EdgeInsets.only(left: 8 + indent, right: 16),
          // 左侧勾选框
          leading: Checkbox(
            value: _selectedNodes.contains(node),
            onChanged: (v) => _toggleSelection(node, v),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Row(
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
          // 递归构建子节点
          children: node.children?.map((child) => _buildNodeItem(child, level + 1)).toList() ?? [],
        ),
      );
    }
    // 如果是文件，使用普通 InkWell + Row
    else {
      return InkWell(
        onTap: () => _toggleSelection(node, !_selectedNodes.contains(node)),
        child: Padding(
          padding: EdgeInsets.only(left: 8 + indent, right: 16, top: 10, bottom: 10),
          child: Row(
            children: [
              Checkbox(
                value: _selectedNodes.contains(node),
                onChanged: (v) => _toggleSelection(node, v),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
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
                      style: const TextStyle(fontSize: 14),
                    ),
                    // 如果有文件大小，可以显示
                    if (node.size != null)
                      Text(
                        _formatSize(node.size!),
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

  // 简单的文件大小格式化辅助方法
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// --- 扩展方法，方便直接调用 ---
extension FileTreeDialogExtension on KikoenaiDialog {
  static Future<void> showFileTree({
    BuildContext? context,
    required List<FileNode> roots,
    required Function(List<FileNode>) onDownload,
    required Function(List<FileNode>) onAddToQueue,
  }) async {
    await KikoenaiDialog.show(
      context: context,
      clickMaskDismiss: true, // 允许点击遮罩关闭
      builder: (context) {
        return FileTreeDialogContent(
          roots: roots,
          onDownload: onDownload,
          onAddToQueue: onAddToQueue,
        );
      },
    );
  }
}