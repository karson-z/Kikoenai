import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/model/file_node.dart';
import '../../../../core/utils/scraper/scraper_controller.dart';
enum _QueueItemType { processing, pending, failed, completed }
class _QueueItem {
  final FileNode node;
  final _QueueItemType type;
  _QueueItem(this.node, this.type);
}
class ScraperQueueDrawer extends ConsumerWidget {
  const ScraperQueueDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(scraperQueueProvider);
    final notifier = ref.read(scraperQueueProvider.notifier);

    // 将四个队列按优先级合并为一个展示列表
    final displayList = [
      ...queueState.processing.map((n) => _QueueItem(n, _QueueItemType.processing)),
      ...queueState.pending.map((n) => _QueueItem(n, _QueueItemType.pending)),
      ...queueState.failed.map((n) => _QueueItem(n, _QueueItemType.failed)),
      ...queueState.completed.map((n) => _QueueItem(n, _QueueItemType.completed)),
    ];

    return Drawer(
      width: 320,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // 1. 抽屉头部与控制台
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "后台解析队列",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        queueState.isIdle
                            ? "当前无排队任务"
                            : "排队中: ${queueState.pending.length}  处理中: ${queueState.processing.length}",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // 清空队列按钮
                      if (!queueState.isIdle || queueState.completed.isNotEmpty || queueState.failed.isNotEmpty)
                        IconButton(
                          tooltip: '清空列表',
                          icon: const Icon(Icons.clear_all, size: 22),
                          onPressed: () {
                            notifier.clearQueue();
                          },
                        ),
                      // 播放/暂停控制按钮
                      IconButton(
                        tooltip: queueState.isRunning ? '暂停解析' : '开始解析',
                        icon: Icon(
                          queueState.isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          size: 36,
                          color: queueState.isRunning ? Colors.orange : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          if (queueState.isRunning) {
                            notifier.pause();
                          } else {
                            notifier.start();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. 全局进度条 (如果有任务在运行或排队)
            if (!queueState.isIdle)
              LinearProgressIndicator(
                value: queueState.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            else
              const Divider(height: 1),

            // 3. 任务列表视图
            Expanded(
              child: displayList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text("队列空空如也", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: displayList.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  return _buildTaskTile(displayList[index], context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个任务卡片
  Widget _buildTaskTile(_QueueItem item, BuildContext context) {
    Color statusColor;
    String statusText;
    Widget? leadingIcon;

    switch (item.type) {
      case _QueueItemType.processing:
        statusColor = Colors.blue;
        statusText = '解析中...';
        leadingIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case _QueueItemType.pending:
        statusColor = Colors.grey.shade600;
        statusText = '排队中';
        leadingIcon = Icon(Icons.schedule, color: statusColor, size: 22);
        break;
      case _QueueItemType.failed:
        statusColor = Colors.red;
        statusText = '失败';
        leadingIcon = Icon(Icons.error_outline, color: statusColor, size: 22);
        break;
      case _QueueItemType.completed:
        statusColor = Colors.green;
        statusText = '已完成';
        leadingIcon = Icon(Icons.check_circle, color: statusColor, size: 22);
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leadingIcon,
      title: Text(
        item.node.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          // 已完成的任务文字置灰
          color: item.type == _QueueItemType.completed ? Colors.grey : null,
        ),
      ),
      subtitle: item.node.rjCode != null
          ? Text(item.node.rjCode!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          statusText,
          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}