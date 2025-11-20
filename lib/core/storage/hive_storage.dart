import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorage {
  static HiveStorage? _instance;
  final Map<String, Box> _boxes = {};
  final List<String> _startupBoxes;

  HiveStorage._internal({List<String> startupBoxes = const []})
      : _startupBoxes = startupBoxes;

  /// 获取单例，并初始化 Hive
  static Future<HiveStorage> getInstance({List<String> startupBoxes = const []}) async {
    if (_instance != null) return _instance!;

    _instance = HiveStorage._internal(startupBoxes: startupBoxes);

    // 获取应用文档目录
    final appDocDir = await getApplicationDocumentsDirectory();

    // Hive 初始化（主目录）
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await Hive.initFlutter('${appDocDir.path}/hive_storage');
    } else {
      await Hive.initFlutter();
    }

    // 启动时打开常用 box
    for (var boxName in startupBoxes) {
      await _instance!._openBox(boxName);
    }

    return _instance!;
  }

  /// 内部打开 box，每个 box 使用单独文件夹管理
  Future<Box> _openBox(String boxName) async {
    if (_boxes.containsKey(boxName)) return _boxes[boxName]!;

    String path;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      path = '${appDocDir.path}/hive_storage/$boxName'; // 每个 box 一个文件夹
      await Directory(path).create(recursive: true);
      final box = await Hive.openBox(boxName, path: path);
      _boxes[boxName] = box;
    } else {
      // 移动端默认路径，Hive 会自动创建文件
      final box = await Hive.openBox(boxName);
      _boxes[boxName] = box;
    }

    return _boxes[boxName]!;
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
