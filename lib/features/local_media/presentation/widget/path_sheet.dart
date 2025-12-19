import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/file_scanner_provider.dart';

class PathManagerSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const PathManagerSheet({super.key, required this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return PathManagerSheet(scrollController: scrollController);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileScannerProvider);
    final notifier = ref.read(fileScannerProvider.notifier);
    final paths = state.rootPaths;

    return Column(
      children: [
        // 1. 把手条
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // 2. 标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "扫描路径管理",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "已添加 ${paths.length} 个文件夹",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              // --- 修改点：改为清空按钮 ---
              TextButton(
                onPressed: paths.isEmpty
                    ? null // 列表为空时禁用
                    : () => _showClearConfirmation(context, notifier),
                child: Text(
                  "清空",
                  style: TextStyle(
                    // 使用错误色（通常是红色）表示破坏性操作
                    color: paths.isEmpty
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              )
            ],
          ),
        ),

        const Divider(height: 1),

        // 3. 列表区域
        Expanded(
          child: paths.isEmpty
              ? _buildEmptyManager(context)
              : ListView.separated(
            controller: scrollController,
            itemCount: paths.length,
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            separatorBuilder: (c, i) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final path = paths[index];
              final folderName = path.split(Platform.pathSeparator).last;
              final parentPath = File(path).parent.path;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  child: const Icon(Icons.folder),
                ),
                title: Text(
                  folderName.isEmpty ? path : folderName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  parentPath,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: "移除此路径",
                  onPressed: () {
                    notifier.removeDirectory(path);
                  },
                ),
              );
            },
          ),
        ),

        // 4. 底部固定按钮
        Container(
            padding: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: FilledButton.icon(
                onPressed: () => notifier.addDirectory(),
                icon: const Icon(Icons.add_rounded),
                label: const Text("添加新目录"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            )),
      ],
    );
  }

  /// 显示二次确认弹窗
  void _showClearConfirmation(BuildContext context, FileScannerNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("清空所有路径?"),
        content: const Text("这将移除当前模式下所有已添加的文件夹及缓存数据，此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              // 执行清空操作
              notifier.clearAllDirectories();
              Navigator.pop(context); // 关弹窗
              // Navigator.pop(context); // 可选：如果清空后想直接关闭底部面板，可以再调一次 pop
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("确认清空"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyManager(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "暂无扫描路径",
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}