import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/v4.dart';

import '../../../features/album/data/model/file_node.dart';
import '../../storage/hive_storage.dart';
import 'package:path/path.dart' as p;
/// 统一管理的下载服务单例
class DownloadService {
  // 1. 单例模式
  static final DownloadService _instance = DownloadService._internal();

  factory DownloadService() => _instance;

  static DownloadService get instance => _instance;

  DownloadService._internal();

  // 2. 公开的流（供 UI 监听）
  static final StreamController<TaskProgressUpdate> _progressController =
      StreamController.broadcast();
  static final StreamController<TaskStatusUpdate> _statusController =
      StreamController.broadcast();

  late String _savePath;

  Stream<TaskProgressUpdate> get progressStream => _progressController.stream;

  Stream<TaskStatusUpdate> get statusStream => _statusController.stream;

  String get savePath => _savePath;

  Box get setting => AppStorage.settingsBox;
  // 初始化标志
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      Directory? systemDir;

      if (Platform.isIOS) {
        systemDir = await getApplicationDocumentsDirectory();
      } else {
        // Android / Desktop: 尝试获取下载目录
        systemDir = await getDownloadsDirectory();
      }
      // 如果 Android 获取下载目录失败 (极少数情况)，兜底使用文档目录
      systemDir ??= await getApplicationDocumentsDirectory();

      final defaultPath = p.join(systemDir.path, 'kikoenaiDownload');

      // 2. 从 Hive 获取自定义路径，如果没有则使用上面的默认路径
      _instance._savePath = _instance.setting.get(
          StorageKeys.fileDownloadKey,
          defaultValue: defaultPath
      );
      debugPrint("下载保存路径已设置为: ${_instance._savePath}");

      // 确保目录存在（如果是首次运行，不仅要获取路径，还要创建文件夹）
      final savedDir = Directory(_instance._savePath);
      if (!savedDir.existsSync()) {
        savedDir.createSync(recursive: true);
      }

    } catch (e) {
      debugPrint("获取下载路径失败: $e");
      final supportDir = await getApplicationSupportDirectory();
      _instance._savePath = p.join(supportDir.path, 'kikoenaiDownload');
    }

    // A. 基础配置
    await FileDownloader().configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 100)),
      (Config.holdingQueue, (5, null, null)),
    ], androidConfig: [
      (Config.useCacheDir, Config.whenAble),
    ], iOSConfig: [
      (Config.localize, {'Cancel': '停止'}),
    ]);

    FileDownloader().start();
    _isInitialized = true;
    debugPrint('DownloadService 初始化完成');
  }

  /// 场景方法：下载并打开 (等待模式)
  Future<void> downloadAndOpen(String url, String filename) async {
    final hasPrem = await _checkNotificationPermission();
    if (!hasPrem) {
      debugPrint("没有权限,不做通知");
    }
    final task = DownloadTask(
        url: url,
        filename: filename,
        baseDirectory: BaseDirectory.applicationSupport, // 临时文件通常放这里
        updates: Updates.statusAndProgress);
    await FileDownloader().download(task);
    await FileDownloader().openFile(task: task);
  }

  /// 批量下载
  /// [selectedFiles]: 用户选中的文件列表
  /// [rootNodes]: 原始的文件树根节点（用于计算相对路径）
  /// [title]: 任务组名
  Future<void> enqueueBatch({
    required List<FileNode> selectedFiles,
    required List<FileNode> rootNodes,
    required String title,
    dynamic metaData
  }) async {
    final hasPrem = await _checkNotificationPermission();
    if (!hasPrem) {
      debugPrint("没有权限,不做通知");
    }

    final String dynamicGroupName = title;

    FileDownloader().registerCallbacks(
        group: dynamicGroupName,
        taskStatusCallback: (update) {
          _statusController.add(update);
        },
        taskProgressCallback: (update) {
          _progressController.add(update);
        }
    );
    // 配置通知
    FileDownloader().configureNotificationForGroup(dynamicGroupName,
        running: TaskNotification(
            '$dynamicGroupName 下载中', '进度: {numFinished}/{numTotal}'),
        complete:
        TaskNotification('$dynamicGroupName 下载完成', '共 {numTotal} 个文件'),
        progressBar: true,
        groupNotificationId: const UuidV4().generate());

    // 将选中的文件转为 Set，提高查找效率 (O(1))
    final Set<FileNode> selectedSet = selectedFiles.toSet();
    // 将根目录设置为rjCode
    final workFileDirectory = p.join(_savePath,metaData['id'].toString());

    List<DownloadTask> tasksToEnqueue = [];

    // --- 核心逻辑：递归遍历树，构建带路径的任务 ---
    void traverseAndBuildTasks(List<FileNode> nodes, String currentRelativePath) {
      for (var node in nodes) {
        if (node.isFolder) {
          final nextPath = p.join(currentRelativePath, node.title);
          if (node.children != null) {
            traverseAndBuildTasks(node.children!, nextPath);
          }
        } else {
          // 如果是文件，检查是否在选中列表中
          if (selectedSet.contains(node)) {
            final String? downloadUrl = node.mediaDownloadUrl ?? node.mediaStreamUrl;

            if (downloadUrl != null && downloadUrl.isNotEmpty) {

              final finalDirectory = p.join(workFileDirectory, currentRelativePath);
              KikoenaiLogger().i('文件下载路径为：$finalDirectory');
              tasksToEnqueue.add(DownloadTask(
                taskId: node.hash,
                url: downloadUrl,
                filename: node.title,
                directory: finalDirectory,
                group: dynamicGroupName,
                metaData: metaData == null ? '' : jsonEncode(metaData),
                updates: Updates.statusAndProgress,
                allowPause: true,
                displayName: node.title,
                retries: 3,
              ));
            }
          }
        }
      }
    }

    // 从根节点开始遍历，初始相对路径为空
    traverseAndBuildTasks(rootNodes, "");

    if (tasksToEnqueue.isNotEmpty) {
      debugPrint("准备入队 ${tasksToEnqueue.length} 个任务");
      // 批量入队
      await FileDownloader().enqueueAll(tasksToEnqueue);
    } else {
      debugPrint("没有有效的任务可下载");
    }
  }

  // --- 控制方法 ---
  Future<void> pauseAll(List<Task> taskList) async {
    await FileDownloader().pauseAll(tasks: taskList as List<DownloadTask>);
  }
  Future<void> resumeAll(List<Task> taskList) async {
    await FileDownloader().resumeAll(tasks: taskList as List<DownloadTask>);
  }
  Future<void> resume(Task task) async {
    await FileDownloader().resume(task as DownloadTask);
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
  Future<void> delFileAndRecord(Task task) async {
    try {
      // 1. 删除数据库中的记录
      await FileDownloader().database.deleteRecordWithId(task.taskId);
      debugPrint("下载记录已删除: ${task.taskId}");

      // 2. 获取文件的完整物理路径
      final String path = await task.filePath();

      // 3. 执行物理删除
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        KikoenaiToast.success("物理文件已删除: $path");
      } else {
        KikoenaiToast.success("文件不存在，跳过删除: $path");
      }
    } catch (e) {
      KikoenaiToast.error("删除文件或记录时出错: $e");
    }
  }
  /// [新增] 根据组名批量删除
  /// 适用于点击 Group Card 上的删除按钮
  Future<void> deleteTasksByGroup(String groupName) async {
    final downloader = FileDownloader();

    try {
      // 1. 【关键】先查询出该组下的所有记录
      // 必须在删除数据库记录之前查，否则就找不到路径了
      final records = await downloader.database.allRecords(group: groupName);

      if (records.isEmpty) {
        debugPrint("该组没有记录: $groupName");
        return;
      }
      // 2. 遍历删除物理文件
      for (var record in records) {
        try {
          final path = await record.task.filePath();
          final file = File(path);

          if (await file.exists()) {
            await file.delete(recursive: true); // recursive: true 对文件夹更安全
            debugPrint("物理文件已删除: $path");
          }
        } catch (e) {
          debugPrint("删除单个文件失败: ${record.task.filename}, 错误: $e");
        }
      }
      // 3. 删除数据库中的记录
      await downloader.database.deleteAllRecords(group: groupName);
      debugPrint("数据库记录已清理: $groupName");
      KikoenaiToast.success("批量删除成功");
    } catch (e) {
      KikoenaiToast.error("批量删除失败: $e");
    }
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

  /// 获取所有任务记录
  Future<List<TaskRecord>> getAllTasks() async {
    return await FileDownloader().database.allRecords();
  }


  // --- 内部辅助 ---

  Future<bool> _checkNotificationPermission() async {
    var status =
        await FileDownloader().permissions.status(PermissionType.notifications);
    if (status != PermissionStatus.granted) {
      status = await FileDownloader()
          .permissions
          .request(PermissionType.notifications);
    }
    return status == PermissionStatus.granted;
  }

  // 销毁（一般单例不销毁，但如果需要重置可调用）
  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}
