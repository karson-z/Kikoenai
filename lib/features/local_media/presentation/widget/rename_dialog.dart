import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../album/data/model/file_node.dart';
import '../provider/file_scanner_provider.dart';

class RenameFileDialog extends ConsumerStatefulWidget {
  final FileNode node;

  const RenameFileDialog({super.key, required this.node});

  /// 静态快捷调用方法
  static void show(BuildContext context, FileNode node) {
    // 1. 前置校验
    final path = node.mediaStreamUrl;

    if (path == null) return;

    // 分别检查文件存在性和文件夹存在性
    final isFileExists = File(path).existsSync();
    final isDirExists = Directory(path).existsSync();

    // 只有当两者都不存在时，才认为是压缩包内的虚拟文件或无效路径
    if (!isFileExists && !isDirExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("仅支持重命名本地物理文件/文件夹，压缩包内文件不支持"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // 2. 显示弹窗
    showDialog(
      context: context,
      builder: (_) => RenameFileDialog(node: node),
    );
  }

  @override
  ConsumerState<RenameFileDialog> createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends ConsumerState<RenameFileDialog> {
  late TextEditingController _controller;
  late String _ext;
  late String _nameWithoutExt;

  @override
  void initState() {
    super.initState();
    final fullName = widget.node.title;
    _ext = p.extension(fullName); // 获取后缀 .mp3
    _nameWithoutExt = p.basenameWithoutExtension(fullName); // 获取文件名 song
    _controller = TextEditingController(text: _nameWithoutExt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRename() async {
    final newNamePart = _controller.text.trim();
    if (newNamePart.isEmpty || newNamePart == _nameWithoutExt) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop();

    final path = widget.node.mediaStreamUrl; // 这是绝对路径
    final notifier = ref.read(fileScannerProvider.notifier);

    try {
      //  直接调用 renamePath，不再需要先去 rawItems 里查找对象
      // 这样就支持了 rawItems 里不存在的“压缩包本身”或“文件夹”
      final success = await notifier.renamePath(path ?? "", newNamePart);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("重命名成功")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("操作失败: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("重命名"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: _ext, // 智能显示后缀
              hintText: "请输入新文件名",
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => _handleRename(), // 允许回车提交
          ),
          const SizedBox(height: 8),
          Text(
            "原路径: ${widget.node.mediaStreamUrl}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: _handleRename,
          child: const Text("确定"),
        ),
      ],
    );
  }
}