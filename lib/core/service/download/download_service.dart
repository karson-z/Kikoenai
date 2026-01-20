import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';

/// 统一管理的下载服务单例
class DownloadService {
  // 1. 单例模式
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  static DownloadService get instance => _instance;

  DownloadService._internal();

  // 2. 公开的流（供 UI 监听）
  final StreamController<TaskProgressUpdate> _progressController = StreamController.broadcast();
  final StreamController<TaskStatusUpdate> _statusController = StreamController.broadcast();

  Stream<TaskProgressUpdate> get progressStream => _progressController.stream;
  Stream<TaskStatusUpdate> get statusStream => _statusController.stream;

  // 初始化标志
  bool _isInitialized = false;

  /// 初始化服务 (在 main 或首页调用)
  Future<void> init() async {
    if (_isInitialized) return;

    // A. 基础配置
    await FileDownloader().configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 100)),
    ], androidConfig: [
      (Config.useCacheDir, Config.whenAble),
    ], iOSConfig: [
      (Config.localize, {'Cancel': '停止'}),
    ]);

    // B. 通知配置 (默认组)
    FileDownloader()
        .configureNotificationForGroup(FileDownloader.defaultGroup,
        running: const TaskNotification(
            '下载中 {filename}', '进度: {progress} - 速度: {networkSpeed}'),
        complete: const TaskNotification('下载完成', '{displayName} 已保存'),
        error: const TaskNotification('下载失败', '{filename}'),
        paused: const TaskNotification('下载暂停', '等待恢复'),
        progressBar: true);

    // C. 注册回调与监听器
    FileDownloader().registerCallbacks(
      taskNotificationTapCallback: (task, notificationType) {
        debugPrint('用户点击了通知: ${task.filename}, 类型: $notificationType');
      },
    );

    // D. 核心监听循环：分发状态和进度
    FileDownloader().updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          _statusController.add(update);
          break;
        case TaskProgressUpdate():
          _progressController.add(update);
          break;
      }
    });

    _isInitialized = true;
    debugPrint('DownloadService 初始化完成');
  }

  /// 核心方法：开始/加入队列下载
  Future<String?> enqueue({
    required String url,
    required String filename,
    String? directory, // 默认为 ApplicationDocuments
    String? group,
    String? displayName,
    Map<String, String>? metaData,
  }) async {
    // 1. 自动检查通知权限
    final hasPerm = await _checkNotificationPermission();
    if (!hasPerm) {
      debugPrint('缺少通知权限');
      // 这里可以决定是抛出异常还是继续静默下载
    }

    // 2. 构建任务
    final task = DownloadTask(
      url: url,
      filename: filename,
      directory: directory ?? 'downloads', // 建议统一子目录
      baseDirectory: BaseDirectory.applicationDocuments,
      group: group ?? FileDownloader.defaultGroup,
      updates: Updates.statusAndProgress, // 确保能收到进度
      displayName: displayName ?? filename,
      metaData: metaData?.toString() ?? '',
      allowPause: true,
      retries: 3,
    );

    // 3. 入队
    final success = await FileDownloader().enqueue(task);
    return success ? task.taskId : null;
  }

  /// 场景方法：下载并打开 (等待模式)
  Future<void> downloadAndOpen(String url, String filename) async {
    await _checkNotificationPermission();

    final task = DownloadTask(
        url: url,
        filename: filename,
        baseDirectory: BaseDirectory.applicationSupport, // 临时文件通常放这里
        updates: Updates.statusAndProgress);

    // 使用 download 而不是 enqueue，会等待直到完成
    await FileDownloader().download(task);
    await FileDownloader().openFile(task: task);
  }

  /// 批量下载示例
  Future<void> enqueueBatch(List<String> urls) async {
    await _checkNotificationPermission();

    // 配置批量通知组（如果尚未配置）
    await FileDownloader().configureNotificationForGroup('batch_group',
        running: const TaskNotification('{numFinished}/{numTotal}', '正在批量下载...'),
        complete: const TaskNotification('全部完成', '共下载 {numTotal} 个文件'),
        progressBar: false);

    for (int i = 0; i < urls.length; i++) {
      await FileDownloader().enqueue(DownloadTask(
        url: urls[i],
        filename: 'file_$i',
        group: 'batch_group',
        updates: Updates.status,
      ));
      // 稍微延迟避免瞬间拥堵
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // --- 控制方法 ---

  Future<void> pause(String taskId) async {
    // 需要通过 id 获取 Task 对象，通常这是复杂的，这里简化为只操作当前任务
    // 实际项目中，建议自己维护一个 Map<String, Task> runningTasks
    // 插件支持直接通过 ID 取消，但暂停通常需要 Task 对象
    // 这里演示取消，暂停需要传入 Task 对象
    await FileDownloader().cancelTasksWithIds([taskId]);
  }

  /// 暂停任务
  /// 接收 String ID，内部自动查找 Task 对象
  Future<bool> pauseTask(String taskId) async {
    // 1. 从数据库找回 Task 对象
    final Task? task = await FileDownloader().taskForId(taskId);

    // 2. 只有 DownloadTask 支持暂停 (UploadTask 不支持)
    if (task != null && task is DownloadTask) {
      return await FileDownloader().pause(task);
    }

    debugPrint('暂停失败: 未找到 ID 为 $taskId 的任务或任务类型不支持');
    return false;
  }

  /// 恢复任务
  /// 接收 String ID，内部自动查找 Task 对象
  Future<bool> resumeTask(String taskId) async {
    // 1. 从数据库找回 Task 对象
    final Task? task = await FileDownloader().taskForId(taskId);

    // 2. 检查对象是否存在
    if (task != null && task is DownloadTask) {
      return await FileDownloader().resume(task);
    }

    debugPrint('恢复失败: 未找到 ID 为 $taskId 的任务');
    return false;
  }

  Future<void> cancel(String taskId) async {
    await FileDownloader().cancelTasksWithIds([taskId]);
  }

  Future<List<TaskRecord>> getDownloadingTasks() async {
    // 获取数据库中所有记录
    final allRecords = await FileDownloader().database.allRecords();

    // 筛选出未完成的任务
    return allRecords.where((record) {
      return record.status == TaskStatus.enqueued ||
          record.status == TaskStatus.running ||
          record.status == TaskStatus.paused;
    }).toList();
  }

  /// 获取所有“已完成”的任务
  /// [group] 可选：如果只想获取特定组的完成记录
  Future<List<TaskRecord>> getCompletedTasks({String? group}) async {
    final allRecords = await FileDownloader().database.allRecords();

    return allRecords.where((record) {
      final isComplete = record.status == TaskStatus.complete;
      // 如果指定了 group，则需匹配 group；否则只看状态
      final isGroupMatch = group == null || record.task.group == group;
      return isComplete && isGroupMatch;
    }).toList();
  }

  /// 获取所有任务记录（用于调试或全部展示）
  Future<List<TaskRecord>> getAllTasks() async {
    return await FileDownloader().database.allRecords();
  }
  // --- 内部辅助 ---

  Future<bool> _checkNotificationPermission() async {
    var status = await FileDownloader().permissions.status(PermissionType.notifications);
    if (status != PermissionStatus.granted) {
      status = await FileDownloader().permissions.request(PermissionType.notifications);
    }
    return status == PermissionStatus.granted;
  }

  // 销毁（一般单例不销毁，但如果需要重置可调用）
  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}