import 'package:flutter/material.dart';

class CloudDriveErrorContent extends StatelessWidget {
  const CloudDriveErrorContent({
    super.key,
    required this.message,
    required this.isRoot,
    required this.isSearch,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final bool isRoot;
  final bool isSearch;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 18),
            Text(
              isSearch ? '搜索失败' : '加载失败',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                if (!isRoot)
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('返回上一页'),
                  ),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CloudDriveEmptyContent extends StatelessWidget {
  const CloudDriveEmptyContent({
    super.key,
    required this.isSearch,
    required this.isDirectoryEmpty,
    required this.onRefresh,
  });

  final bool isSearch;
  final bool isDirectoryEmpty;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchEmpty = isSearch || !isDirectoryEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searchEmpty ? Icons.search_off : Icons.folder_open,
            size: 60,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            searchEmpty ? '没有匹配的文件' : '该目录为空',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!searchEmpty) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('刷新'),
            ),
          ],
        ],
      ),
    );
  }
}

class CloudDriveFooter extends StatelessWidget {
  const CloudDriveFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadedCount,
    required this.totalCount,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int loadedCount;
  final int totalCount;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Center(
          child: TextButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.expand_more, size: 18),
            label: const Text('加载更多'),
          ),
        ),
      );
    }
    final resolvedTotal = totalCount == 0 ? loadedCount : totalCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      child: Text(
        '已显示 $loadedCount / $resolvedTotal 项',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
