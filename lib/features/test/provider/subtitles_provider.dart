import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:kikoenai/core/storage/hive_key.dart';
import '../../../core/constants/app_file_extensions.dart';
import '../../../core/constants/app_regex_str.dart';
import '../../../core/service/import_file_service.dart';
import '../../../core/service/path_setting_service.dart';
import '../state/improt_state.dart';


/// 【核心修改】存储字幕的根目录
/// 现在改为从 PathSettingsService 获取配置的路径
final subtitleRootProvider = FutureProvider<String>((ref) async {
  final pathService = PathSettingsService();
  // 获取用户设置的 'Subtitle' 路径
  final path = await pathService.getPath(StorageKeys.pathSubtitle);

  // 双重保险：确保拿到的这个路径文件夹确实存在
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return path;
});

/// 当前浏览的路径状态 (默认是 null，代表根目录)
final currentPathProvider = StateProvider<String?>((ref) => null);

/// 获取当前路径下的文件列表
final directoryContentsProvider = FutureProvider.autoDispose<List<FileSystemEntity>>((ref) async {
  // 1. 等待根目录获取完成
  final rootPath = await ref.watch(subtitleRootProvider.future);

  // 2. 确定当前要显示的目录 (如果没有选中子目录，就显示根目录)
  final currentPath = ref.watch(currentPathProvider) ?? rootPath;

  final dir = Directory(currentPath);
  if (!await dir.exists()) return [];

  // 3. 列出文件并排序
  final List<FileSystemEntity> entities = await dir.list().toList();

  // 排序规则：文件夹在前，文件在后；同类按名称排序
  entities.sort((a, b) {
    bool aIsDir = FileSystemEntity.isDirectorySync(a.path);
    bool bIsDir = FileSystemEntity.isDirectorySync(b.path);
    if (aIsDir && !bIsDir) return -1;
    if (!aIsDir && bIsDir) return 1;
    return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
  });

  return entities;
});
final fileImportProvider = AsyncNotifierProvider<FileImportNotifier, ImportState>(() => FileImportNotifier());
class FileImportNotifier extends AsyncNotifier<ImportState> {
  // 1. 初始化方法 (必须实现)
  @override
  FutureOr<ImportState> build() {
    // 初始状态：进度为 0
    return const ImportState();
  }

  // 2. 业务逻辑
  Future<void> importFiles(ImportFileType type) async {
    // 读取其他 Provider
    final currentDir = ref.read(currentPathProvider);
    if (currentDir == null) return;

    final hasPermission = await FileImportService().requestPermissions();
    if (!hasPermission) {
      // 手动抛出错误，UI 会收到 AsyncError
      state = AsyncValue.error("无文件访问权限", StackTrace.current);
      return;
    }

    // 文件选择逻辑 (为了简洁省略部分细节)
    List<String> paths = [];
    if (type == ImportFileType.folder) {
      final p = await FilePicker.platform.getDirectoryPath();
      if (p != null) paths.add(p);
    } else {
      final res = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (res != null) paths = res.paths.whereType<String>().toList();
    }
    if (paths.isEmpty) return;

    // --- 开始导入 ---

    // 步骤 A: 设置为 Loading 状态
    // 注意：如果我们想保留之前的进度显示(虽然是0)，可以使用 copyWithPrevious
    state = const AsyncValue.loading();

    try {
      final targetPath = FileImportService().generateTargetPath(
          paths.first, currentDir, type, idRegexPattern: RegexPatterns.workId);

      final actualType = type == ImportFileType.folder
          ? ImportFileType.folder
          : FileImportService().identifyImportType(paths);

      await FileImportService().importFile(
        sourcePaths: paths,
        destinationPath: targetPath,
        type: actualType,
        allowedExtensions: FileExtensions.subtitles,
        idRegexPattern: RegexPatterns.workId,
        onProgress: (progress, fileName) {
          // 步骤 B: 更新进度
          // 我们使用 AsyncValue.data 来更新数据，代表"当前还是正常数据状态，只是数值变了"
          // 如果你希望进度条更新时 UI 不闪烁 Loading 圈，这里使用 AsyncData 是对的
          state = AsyncValue.data(ImportState(
            progress: progress,
            currentFile: fileName,
          ));
        },
      );

      // 步骤 C: 完成
      ref.invalidate(directoryContentsProvider);
      state = const AsyncValue.data(ImportState(progress: 1.0, currentFile: "完成"));

    } catch (e, st) {
      // 步骤 D: 错误处理
      state = AsyncValue.error(e, st);
    }
  }
  /// 文件迁移逻辑
  Future<void> migrateDirectory(FileSystemEntity sourceEntity) async {
    // 1. 获取根目录 (依赖检查)
    final rootPathAsync = ref.read(subtitleRootProvider);
    final rootPath = rootPathAsync.value;

    if (rootPath == null) {
      state = AsyncValue.error("根目录未就绪", StackTrace.current);
      return;
    }

    // 2. 选择目标文件夹 (交互逻辑)
    // 虽然 FilePicker 是 UI 交互，但在 Notifier 中 await 它是常见的做法，
    // 这样可以将"用户取消"和"逻辑校验"都封装在 Controller 里
    String? targetDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "选择迁移目标位置",
      initialDirectory: rootPath,
      lockParentWindow: true,
    );

    if (targetDir == null) return; // 用户取消，什么都不做，状态不变

    // 3. 路径校验
    final bool isInsideRoot = p.isWithin(rootPath, targetDir);
    final bool isRootItSelf = p.equals(rootPath, targetDir);

    if (!isInsideRoot && !isRootItSelf) {
      state = AsyncValue.error("禁止操作：只能迁移到字幕库目录内部！", StackTrace.current);
      return;
    }

    if (p.isWithin(sourceEntity.path, targetDir) || p.equals(sourceEntity.path, targetDir)) {
      state = AsyncValue.error("无效操作：不能迁移到自己或自己的子文件夹中", StackTrace.current);
      return;
    }

    // 4. 开始执行
    state = const AsyncValue.loading(); // 触发 UI 显示遮罩

    try {
      final newPath = p.join(targetDir, p.basename(sourceEntity.path));

      // 给 UI 一个正在处理的反馈 (模拟 50% 进度，因为迁移通常很快或者是原子操作)
      state = const AsyncValue.data(ImportState(progress: 0.5, currentFile: "正在迁移..."));

      await FileImportService().migrateDirectory(sourceEntity.path, newPath);

      // 5. 成功
      ref.invalidate(directoryContentsProvider); // 刷新文件列表

      // 标记完成，进度 100%
      state = const AsyncValue.data(ImportState(progress: 1.0, currentFile: "完成"));

    } catch (e, st) {
      state = AsyncValue.error("迁移失败: $e", st);
    }
  }
}