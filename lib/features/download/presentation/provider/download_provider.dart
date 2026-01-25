import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service/download/download_service.dart';

// Service Provider 保持不变
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService.instance;
});

final allTasksProvider = AsyncNotifierProvider<AllTasksNotifier, List<TaskRecord>>(
      () => AllTasksNotifier(),
);

class AllTasksNotifier extends AsyncNotifier<List<TaskRecord>> {
  @override
  Future<List<TaskRecord>> build() async {

    final service = ref.watch(downloadServiceProvider);
    final statusSub = service.statusStream.listen(_onStatusUpdate);
    final progressSub = service.progressStream.listen(_onProgressUpdate);

    ref.onDispose(() {
      statusSub.cancel();
      progressSub.cancel();
    });

    return await service.getAllTasks();
  }
  Future<void> deleteTask(Task task) async {
    // 1. 先操作 Service (异步)
    final service = ref.read(downloadServiceProvider);
    await service.delFileAndRecord(task);

    final currentList = state.value;
    if (currentList != null) {
      // 创建新列表，移除该 ID 的元素
      final newList = currentList.where((r) => r.task.taskId != task.taskId).toList();
      state = AsyncData(newList);
    }
  }
  Future<void> deleteGroup(String groupName) async {
    try {
      // 1. 调用 Service 执行实际删除
      final service = ref.read(downloadServiceProvider);
      await service.deleteTasksByGroup(groupName);

      // 2. 手动更新 State (从内存列表中移除该组)
      // 原因：数据库删除操作不会触发 statusStream 的更新事件，
      // 所以我们需要手动把它们从当前的 UI 列表中踢出去。
      final currentList = state.value;
      if (currentList != null) {
        // 过滤掉所有 group 等于目标 groupName 的记录
        final newList = currentList.where((r) => r.task.group != groupName).toList();
        // 赋值新状态 -> 触发 UI 重绘
        state = AsyncData(newList);
      }
    } catch (e) {
      // 如果 Service 报错了，这里捕获异常，UI 列表不变化
      debugPrint("Notifier 删除组失败: $e");
    }
  }
  void _updateList(TaskRecord newRecord) {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((r) => r.task.taskId == newRecord.task.taskId);

    if (index != -1) {
      // 更新现有记录
      final newList = List<TaskRecord>.from(currentList);
      newList[index] = newRecord;
      state = AsyncData(newList);
    } else {
      // 插入新记录 (通常是新任务加入)
      state = AsyncData([...currentList, newRecord]);
    }
  }
  /// 处理状态变更 (Status Update)
  void _onStatusUpdate(TaskStatusUpdate update) {
    final currentList = state.value;
    if (currentList == null) return;

    // 尝试找到旧记录以继承进度信息
    final oldRecord = currentList.firstWhere(
            (r) => r.task.taskId == update.task.taskId,
        orElse: () => TaskRecord(update.task, TaskStatus.enqueued, 0, -1, null) // 兜底
    );

    // 构造新状态记录
    final newRecord = TaskRecord(
        update.task,
        update.status,
        oldRecord.progress, // 继承旧进度
        oldRecord.expectedFileSize,
        update.exception
    );

    _updateList(newRecord);
  }

  /// 处理进度变更 (Progress Update)
  void _onProgressUpdate(TaskProgressUpdate update) {
    final currentList = state.value;
    if (currentList == null) return;

    final index = currentList.indexWhere((r) => r.task.taskId == update.task.taskId);

    if (index != -1) {
      final oldRecord = currentList[index];

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

// 4.过滤已完成的任务
final completedTasksProvider = Provider<List<TaskRecord>>((ref) {
  final asyncValue = ref.watch(allTasksProvider);
  return asyncValue.when(
    data: (tasks) => tasks.where((r) => r.status == TaskStatus.complete).toList(),
    error: (_, __) => [],
    loading: () => [],
  );
});
//5.获取分组任务列表
final completedTasksByGroupProvider = Provider.family<List<TaskRecord>, String?>((ref, groupName) {
  // 1. 获取所有已完成任务
  final allCompleted = ref.watch(completedTasksProvider);
  // 2. 如果没传组名，返回全部
  if (groupName == null || groupName.isEmpty) {
    return allCompleted;
  }
  // 3. 否则按组名过滤
  return allCompleted.where((r) => r.task.group == groupName).toList();
});