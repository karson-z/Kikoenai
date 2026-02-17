import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/file_scanner_notifier.dart';

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
    final paths = state.savedPaths;
    // 获取当前正在浏览的路径（如果有）
    final currentPath = state.currentPath;

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
                    "点击列表切换路径", // 提示用户可以点击
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: paths.isEmpty
                    ? null
                    : () => _showClearConfirmation(context, notifier),
                child: Text(
                  "清空",
                  style: TextStyle(
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
            separatorBuilder: (c, i) =>
            const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final path = paths[index];
              final folderName = path.split(Platform.pathSeparator).last;
              final parentPath = File(path).parent.path;

              // 判断是否是当前选中的路径
              final isSelected = path == currentPath;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 4),
                // 选中状态样式
                selected: isSelected,
                selectedTileColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.1),
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  foregroundColor: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                      .colorScheme
                      .onSecondaryContainer,
                  child: Icon(
                    isSelected ? Icons.check : Icons.folder,
                  ),
                ),
                title: Text(
                  folderName.isEmpty ? path : folderName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  parentPath,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // --- 核心修改：点击事件 ---
                onTap: () {
                  // 1. 触发扫描
                  notifier.startScan(path);
                  // 2. 关闭弹窗
                  Navigator.pop(context);
                },
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
  void _showClearConfirmation(
      BuildContext context, FileScannerNotifier notifier) {
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
              notifier.clearAllDirectories();
              Navigator.pop(context);
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