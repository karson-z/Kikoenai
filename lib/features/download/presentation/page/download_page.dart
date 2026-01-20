import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service/download/download_service.dart';
import '../provider/download_provider.dart';

class RiverpodDownloadPage extends ConsumerWidget {
  const RiverpodDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听两个过滤后的列表
    final downloadingList = ref.watch(downloadingTasksProvider);
    final completedList = ref.watch(completedTasksProvider);

    // 获取 Service 实例用于触发操作 (enqueue, pause 等)
    final downloadService = ref.read(downloadServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riverpod 下载管理'),
          bottom: const TabBar(
            tabs: [Tab(text: '进行中'), Tab(text: '已完成')],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                // 测试添加任务
                await downloadService.enqueue(
                  url: 'https://storage.googleapis.com/approachcharts/test/5MB-test.ZIP',
                  filename: 'test_file_${DateTime.now().second}.zip',
                );
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: 下载中
            _buildDownloadingList(downloadingList, downloadService),
            // Tab 2: 已完成
            _buildCompletedList(completedList, downloadService),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingList(List<TaskRecord> list, DownloadService service) {
    if (list.isEmpty) {
      return const Center(child: Text("没有正在进行的任务"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        final isPaused = record.status == TaskStatus.paused;

        return ListTile(
          title: Text(record.task.filename),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              LinearProgressIndicator(value: record.progress),
              const SizedBox(height: 5),
              Text('${(record.progress * 100).toStringAsFixed(1)}% - ${record.status.name}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () {
                  if (isPaused) {
                    service.resumeTask(record.task.taskId);
                  } else {
                    service.pauseTask(record.task.taskId);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => service.cancel(record.task.taskId),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedList(List<TaskRecord> list, DownloadService service) {
    if (list.isEmpty) {
      return const Center(child: Text("没有已完成的任务"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(record.task.filename),
          subtitle: const Text('下载完成'),
          onTap: () {
            FileDownloader().openFile(task: record.task);
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // 如果需要删除记录和文件，可以在 Service 中添加 delete 方法
              // Service.instance.removeTask(record.task.taskId);
            },
          ),
        );
      },
    );
  }
}