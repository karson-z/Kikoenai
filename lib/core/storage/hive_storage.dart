import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/adapter/work_adapter.dart';
import 'package:path_provider/path_provider.dart';
import '../adapter/file_node_adapter.dart';
import '../adapter/history_adapter.dart';
import '../adapter/media_item_adapter.dart';
import '../adapter/player_state_adapter.dart';
import '../adapter/progressbar_state_adapter.dart';
import '../adapter/work_info_adapter.dart';

class HiveStorage {
  static HiveStorage? _instance;
  final Map<String, Box> _boxes = {};
  final List<String> _startupBoxes;

  HiveStorage._internal({List<String> startupBoxes = const []})
      : _startupBoxes = startupBoxes;

  /// 获取单例，并初始化 Hive
  static Future<HiveStorage> getInstance({List<String> startupBoxes = const []}) async {
    if (_instance != null) return _instance!;

    // 1. 先获取路径并初始化 Hive
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      // 统一指定根目录，之后 openBox 不需要再手动拼路径
      await Hive.initFlutter('${appDocDir.path}/hive_storage');
      debugPrint("Hive Desktop Root: ${appDocDir.path}/hive_storage");
    } else {
      await Hive.initFlutter();
    }
    // 2. 注册所有 Adapter
    Hive.registerAdapter(ProgressBarStateAdapter());
    Hive.registerAdapter(MediaItemAdapter());
    Hive.registerAdapter(WorkInfoAdapter());
    Hive.registerAdapter(FileNodeAdapter());
    Hive.registerAdapter(PlayerStateAdapter());
    Hive.registerAdapter(WorkAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());

    // 3. 创建实例
    _instance = HiveStorage._internal();

    // 4. 启动时打开常用 box
    for (var boxName in startupBoxes) {
      await _instance!._openBox(boxName);
    }

    return _instance!;
  }

  /// 内部打开 box，每个 box 使用单独文件夹管理
  Future<Box> _openBox(String boxName) async {
    // 1. 如果内存缓存中有，直接返回
    if (_boxes.containsKey(boxName)) return _boxes[boxName]!;

    try {
      // 2. 尝试正常打开
      final box = await Hive.openBox(boxName);
      _boxes[boxName] = box;
      return box;
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (delError) {
        debugPrint("删除 Box 失败 (可能文件被占用): $delError");
      }
      final box = await Hive.openBox(boxName);
      _boxes[boxName] = box;
      return box;
    }
  }

  /// 公共接口：打开 box
  Future<Box> openBox(String boxName) async {
    return _openBox(boxName);
  }

  /// 保存对象
  Future<void> put(String boxName, String key, dynamic value) async {
    final box = await _openBox(boxName);
    await box.put(key, value);
  }

  /// 获取对象
  Future<dynamic> get(String boxName, String key) async {
    final box = await _openBox(boxName);
    return box.get(key);
  }

  /// 删除对象
  Future<void> delete(String boxName, String key) async {
    final box = await _openBox(boxName);
    await box.delete(key);
  }

  /// 清空某个 box
  Future<void> clearBox(String boxName) async {
    final box = await _openBox(boxName);
    await box.clear();
  }

  /// 清空所有已打开 box
  Future<void> clearAll() async {
    for (var box in _boxes.values) {
      await box.clear();
    }
  }
}
