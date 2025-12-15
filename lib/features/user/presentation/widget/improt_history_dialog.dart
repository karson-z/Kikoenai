import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../../core/service/file_service.dart';

/// 调用此方法显示弹窗
void showImportHistoryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ImportHistoryDialog(),
  );
}

class _ImportHistoryDialog extends StatefulWidget {
  const _ImportHistoryDialog();

  @override
  State<_ImportHistoryDialog> createState() => _ImportHistoryDialogState();
}

class _ImportHistoryDialogState extends State<_ImportHistoryDialog> {
  List<String> _paths = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  double _progress = 0.0;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final paths = await FileService.getRecordedPaths();
    if (mounted) {
      setState(() {
        _paths = paths;
        _isLoading = false;
      });
    }
  }
  Future<void> _deleteSingleFile(int index) async {
    final path = _paths[index];

    // 1. 物理删除文件
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print("已物理删除: $path");
      }
    } catch (e) {
      print("文件删除出错 (可能文件已被手动删除): $e");
      // 即使出错，通常也应该从列表中移除，避免死循环
    }

    // 2. 更新 UI
    setState(() {
      _paths.removeAt(index);
    });

    // 3. 同步更新本地 JSON 记录，防止下次打开还在
    await FileService.overwriteRecords(_paths);

    // 4. (可选) 给个轻提示
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars(); // 清除旧的防止堆积
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("已删除: ${p.basename(path)}"),
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating, // 浮动样式，避免遮挡
        ),
      );
    }
  }
  /// 执行物理删除逻辑
  Future<void> _executeDeleteAll() async {
    if (_paths.isEmpty) return;

    // 二次确认
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认清理"),
        content: const Text("这将物理删除源文件，此操作不可恢复。\n确认要执行吗？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("彻底删除"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _statusMessage = "正在清理...";
    });

    int successCount = 0;
    int total = _paths.length;

    for (int i = 0; i < total; i++) {
      final path = _paths[i];
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        successCount++;
      } catch (e) {
        print("删除失败: $path - $e");
      }

      if (mounted) {
        setState(() {
          _progress = (i + 1) / total;
        });
      }
    }

    // 清理 JSON 记录
    await FileService.clearRecords();

    if (mounted) {
      setState(() {
        _isDeleting = false;
        _paths.clear();
        _statusMessage = "清理完成，共移除 $successCount 个文件";
      });

      // 延迟关闭或让用户手动关闭
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  /// 仅从列表中移除记录（不删除物理文件）
  Future<void> _removeFromList(int index) async {
    setState(() {
      _paths.removeAt(index);
    });
    // 更新本地存储的 JSON，防止下次打开还在
    // 注意：这里需要 FileService 提供一个覆写方法，或者这里简单处理为
    // 暂时不回写，等全部清理，或者你可以扩展 FileService 增加 removePath 方法
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("已导入源文件管理"),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_isDeleting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(_statusMessage),
        ],
      );
    }

    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_paths.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "没有待清理的源文件记录",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "以下文件已成功导入到新位置，你可以选择删除原始文件以释放空间。",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        const Divider(),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _paths.length,
            itemBuilder: (context, index) {
              final path = _paths[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  p.basename(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _deleteSingleFile(index),
                  tooltip: "删除当个记录",
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_isDeleting || _isLoading) return [];

    if (_paths.isEmpty) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("关闭"),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("稍后处理"),
      ),
      TextButton(
        onPressed: () async {
          // 仅清空记录，不删除文件
          await FileService.clearRecords();
          if(mounted) Navigator.pop(context);
        },
        child: const Text("忽略记录"),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.red),
        onPressed: _executeDeleteAll,
        icon: const Icon(Icons.delete),
        label: const Text("一键物理删除"),
      ),
    ];
  }
}