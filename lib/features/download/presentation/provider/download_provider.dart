import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service/download/download_service.dart';

// Service Provider 保持不变
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService.instance;
});

// AllTasksNotifier 修正版
final allTasksProvider = AsyncNotifierProvider<AllTasksNotifier, List<TaskRecord>>(
      () => AllTasksNotifier(),
);

class AllTasksNotifier extends AsyncNotifier<List<TaskRecord>> {
  @override
  Future<List<TaskRecord>> build() async {
    final service = ref.watch(downloadServiceProvider);
    await service.init();

    final statusSub = service.statusStream.listen(_onStatusUpdate);
    final progressSub = service.progressStream.listen(_onProgressUpdate);

    ref.onDispose(() {
      statusSub.cancel();
      progressSub.cancel();
    });

    return await service.getAllTasks();
  }

  /// 处理状态变更 (Status Update)
  void _onStatusUpdate(TaskStatusUpdate update) {
    final currentList = state.value;
    if (currentList == null) return;

    final index = currentList.indexWhere((r) => r.task.taskId == update.task.taskId);

    if (index != -1) {
      // --- 情况 A: 更新已有任务的状态 ---
      final oldRecord = currentList[index];

      // 构造新 Record：
      // 1. task: 来自 update
      // 2. status: 来自 update
      // 3. progress: 继承旧值 (状态变更通常不携带进度，保持原样)
      // 4. expectedFileSize: 继承旧值 (必需参数)
      // 5. exception:如果是失败状态，update.exception 可能有值
      final newRecord = TaskRecord(
          update.task,
          update.status,
          oldRecord.progress,
          oldRecord.expectedFileSize, // <--- 修复点：传入旧的文件大小
          update.exception
      );

      final newList = List<TaskRecord>.from(currentList);
      newList[index] = newRecord;
      state = AsyncData(newList);
    } else {
      // --- 情况 B: 新任务入队 ---
      // 构造新 Record：
      // 3. progress: 默认为 0.0
      // 4. expectedFileSize: 默认为 -1 (未知大小)
      final newRecord = TaskRecord(
          update.task,
          update.status,
          0.0,
          -1, // <--- 修复点：新任务大小未知，传 -1
          update.exception
      );
      state = AsyncData([...currentList, newRecord]);
    }
  }

  /// 处理进度变更 (Progress Update)
  void _onProgressUpdate(TaskProgressUpdate update) {
    final currentList = state.value;
    if (currentList == null) return;

    final index = currentList.indexWhere((r) => r.task.taskId == update.task.taskId);

    if (index != -1) {
      final oldRecord = currentList[index];

      // --- 情况 C: 更新进度 ---
      // update 对象中通常包含：task, progress, expectedFileSize
      final newRecord = TaskRecord(
          update.task,
          oldRecord.status, // 进度更新不改变状态（状态通常还是 running）
          update.progress,
          update.expectedFileSize, // <--- 修复点：进度事件通常包含最新的文件总大小
          null // 进度更新通常没有异常
      );

      final newList = List<TaskRecord>.from(currentList);
      newList[index] = newRecord;
      state = AsyncData(newList);
    }
  }
}
// 3. 衍生 Provider (Selectors)：过滤正在下载的任务
final downloadingTasksProvider = Provider<List<TaskRecord>>((ref) {
  final asyncValue = ref.watch(allTasksProvider);
  return asyncValue.when(
    data: (tasks) => tasks.where((r) =>
    r.status == TaskStatus.enqueued ||
        r.status == TaskStatus.running ||
        r.status == TaskStatus.paused
    ).toList(),
    error: (_, __) => [],
    loading: () => [],
  );
});

// 4. 衍生 Provider (Selectors)：过滤已完成的任务
final completedTasksProvider = Provider<List<TaskRecord>>((ref) {
  final asyncValue = ref.watch(allTasksProvider);
  return asyncValue.when(
    data: (tasks) => tasks.where((r) => r.status == TaskStatus.complete).toList(),
    error: (_, __) => [],
    loading: () => [],
  );
});