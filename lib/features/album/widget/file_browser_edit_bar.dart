import 'package:flutter/material.dart';

class FileBrowserEditBar extends StatelessWidget {
  const FileBrowserEditBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onSelectEligible,
    required this.onEnqueue,
    this.isLoading = false,
    this.onExclude,
    this.onManageExclusions,
    this.onRename,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectEligible;
  final VoidCallback onEnqueue;
  final bool isLoading;
  final VoidCallback? onExclude;
  final VoidCallback? onManageExclusions;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text('已选 $selectedCount',
                style: Theme.of(context).textTheme.labelMedium),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : onSelectAll,
                      child: const Text('全选'),
                    ),
                    TextButton(
                        onPressed: isLoading ? null : onSelectEligible,
                        child: const Text('待解析')),
                    TextButton(
                      onPressed:
                          selectedCount == 0 || isLoading ? null : onEnqueue,
                      child: const Text('加入队列'),
                    ),
                    if (onExclude != null)
                      TextButton(
                        onPressed: selectedCount == 0 ? null : onExclude,
                        child: const Text('排除'),
                      ),
                    if (onRename != null)
                      TextButton(
                        onPressed: selectedCount == 0 ? null : onRename,
                        child: const Text('重命名'),
                      ),
                    if (onManageExclusions != null)
                      IconButton(
                        tooltip: '管理排除项',
                        onPressed: onManageExclusions,
                        icon: const Icon(Icons.rule_folder_outlined),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
