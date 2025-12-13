import 'package:kikoenai/core/service/import_file_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../storage/hive_key.dart';
import '../storage/hive_storage.dart';

class PathSettingsService {
  static const String _settingsBox = 'app_settings';

  /// 配置：定义每个 Key 对应的默认文件夹名称
  /// 如果 Hive 里没有值，就会用这个名字在文档目录下创建文件夹
  static final Map<String, String> _defaultFolderNames = {
    StorageKeys.pathSubtitle: 'Subtitle', // 对应 .../Documents/Subtitle
    StorageKeys.pathVideo:    'Video',    // 对应 .../Documents/Video
    StorageKeys.pathAudio:    'Audio',
    StorageKeys.pathImage:    'Image',
    StorageKeys.pathArchive:  'Archive',
  };
  /// 重置为默认路径
  Future<String> resetPath(String key) async {
    final storage = await HiveStorage.getInstance();

    // 1. 获取当前的自定义路径
    final String? oldPath = await storage.get(_settingsBox, key);

    // 2. 计算默认路径 (逻辑同 getPath 中的默认值逻辑)
    final appDocDir = await getApplicationDocumentsDirectory();
    final folderName = _defaultFolderNames[key] ?? 'Downloads';
    final defaultPath = p.join(appDocDir.path, folderName);

    // 3. 如果当前路径和默认路径不一样，则执行迁移并保存
    if (oldPath != null && oldPath != defaultPath) {
      // 复用 setPath 的逻辑，它内部应该包含 migrateDirectory
      await FileImportService().migrateDirectory(oldPath, defaultPath);
      await setPath(key, defaultPath);
    } else {
      // 如果本来就是默认路径，或者是空的，直接保存确保一致性
      await setPath(key, defaultPath);
    }

    return defaultPath;
  }
  /// 保存路径
  /// [key]: 使用 StorageKeys 中的常量
  /// [path]: 完整的路径字符串
  Future<void> setPath(String key, String path) async {
    final storage = await HiveStorage.getInstance();
    await storage.put(_settingsBox, key, path);
  }

  /// 获取路径
  /// [key]: 使用 StorageKeys 中的常量
  Future<String> getPath(String key) async {
    final storage = await HiveStorage.getInstance();

    // 1. 尝试通过 Key 从 Hive 获取
    final String? savedPath = await storage.get(_settingsBox, key);

    // 2. 如果 Hive 里有值，直接返回
    if (savedPath != null && savedPath.isNotEmpty) {
      return savedPath;
    }

    // 3. 如果没有值，开始计算默认路径
    final appDocDir = await getApplicationDocumentsDirectory();

    // 从映射表中查找默认文件夹名，如果找不到（比如传了个未定义的Key），这就默认叫 'Downloads'
    final folderName = _defaultFolderNames[key] ?? 'Downloads';

    final defaultPath = p.join(appDocDir.path, folderName);

    // 4. 保存这个默认值到 Hive，下次就不用计算了
    await setPath(key, defaultPath);

    return defaultPath;
  }
}