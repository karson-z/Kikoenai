import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import '../provider/file_scanner_notifier.dart';
import 'package:kikoenai/core/service/file/local_batch_rename.dart';

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
    _ext = widget.node.isFolder ? '' : p.extension(fullName);
    _nameWithoutExt =
        widget.node.isFolder ? fullName : p.basenameWithoutExtension(fullName);
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
    try {
      const service = LocalBatchRename();
      final proposal = RenameProposal(widget.node, '$newNamePart$_ext');
      final errors = service.validate([proposal]);
      if (errors.isNotEmpty) throw StateError(errors.values.first);
      final result = await service.execute([proposal]);
      if (result.failed.isNotEmpty) {
        throw StateError(result.failed.values.first);
      }
      if (!mounted) return;
      final notifier = ref.read(fileScannerProvider.notifier);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      await notifier.refreshCurrentTarget();
      messenger.showSnackBar(const SnackBar(content: Text('重命名成功')));
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
    return KikoenaiAlertDialog(
      titleText: "重命名",
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        KikoenaiAlertDialog.textAction(
          context,
          label: "取消",
          onPressed: () => Navigator.of(context).pop(),
        ),
        KikoenaiAlertDialog.textAction(
          context,
          label: "确定",
          isConfirm: true,
          onPressed: _handleRename,
        ),
      ],
    );
  }
}
