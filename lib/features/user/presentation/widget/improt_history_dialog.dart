import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
// 确保导入您的 FileService
import '../../../../core/service/file_service.dart';

/// 调用此方法显示弹窗
void showImportHistoryDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // 正在删除时防止误触关闭
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
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("文件删除出错: $e");
    }

    setState(() {
      _paths.removeAt(index);
    });
    await FileService.overwriteRecords(_paths);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("已删除: ${p.basename(path)}"),
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _executeDeleteAll() async {
    if (_paths.isEmpty) return;

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
        debugPrint("删除失败: $path - $e");
      }

      if (mounted) {
        setState(() {
          _progress = (i + 1) / total;
        });
      }
    }

    await FileService.clearRecords();

    if (mounted) {
      setState(() {
        _isDeleting = false;
        _paths.clear();
        _statusMessage = "清理完成，共移除 $successCount 个文件";
      });

      // 延迟一秒自动关闭，体验更好
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 500, // 👈 保持高度限制
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            // 中间内容区域，使用 Expanded 自动填充剩余空间
            Expanded(
              child: _buildBody(),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.amber), // 换个图标区分
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '已导入源文件管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 如果正在删除，禁用关闭按钮
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // --- Body (根据状态切换内容) ---
  Widget _buildBody() {
    // 1. 正在删除中
    if (_isDeleting) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    // 2. 正在加载数据
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. 数据为空
    if (_paths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "没有待清理的源文件记录",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // 4. 显示文件列表
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            "以下文件已成功导入到新位置，建议删除原始文件以释放空间。",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _paths.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final path = _paths[index];
              return ListTile(
                title: Text(
                  p.basename(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => _deleteSingleFile(index),
                  tooltip: "移除此记录",
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Footer (操作按钮区) ---
  Widget _buildFooter(BuildContext context) {
    // 如果正在删除或加载，不显示按钮
    if (_isDeleting || _isLoading) return const SizedBox.shrink();

    // 如果没有数据，只显示“关闭”
    if (_paths.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ),
      );
    }

    // 有数据时，显示操作按钮组
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("稍后处理"),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await FileService.clearRecords(); // 只清除记录
              if (mounted) Navigator.pop(context);
            },
            child: const Text("忽略记录"),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400, // 柔和一点的红色
              foregroundColor: Colors.white,
            ),
            onPressed: _executeDeleteAll,
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text("一键删除"),
          ),
        ],
      ),
    );
  }
}