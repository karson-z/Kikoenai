import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_storage.dart';
import '../../../../core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';

class ScannerPathRepository {
  ScannerPathRepository._();
  static final ScannerPathRepository instance = ScannerPathRepository._();

  /// 全局静态 Box 实例
  Box<ScanTarget> get scanTargetBox => AppStorage.scanTargetBox;

  /// 生成统一的 Hive Key，确保同一路径在不同扫描模式下拥有独立的存储身份
  static String _generateKey(String path, ScanMode mode) {
    final normalizedPath = path.replaceAll('\\', '/').toLowerCase();
    return '${mode.name}_$normalizedPath';
  }

  String activeKey = 'active_path';

  Future<void> saveActiveTarget(ScanTarget target) async {
    await scanTargetBox.put(activeKey, target);

    debugPrint(
      '[ScannerPathRepository] Saved active target for ${target.scanMode.name}: ${target.path}',
    );
  }

  ScanTarget? getActiveTarget() {
    final activeTarget = scanTargetBox.get(activeKey);
    if (activeTarget != null) {
      final realKey = _generateKey(activeTarget.path, activeTarget.scanMode);
      if (scanTargetBox.containsKey(realKey)) {
        return scanTargetBox.get(realKey);
      }
    }
    return null;
  }

  /// 保存或更新一个扫描目标
  /// 无论是用户新添加，还是扫描完成后更新 [lastScannedAt]，都调用此方法
  Future<void> saveTarget(ScanTarget target) async {
    final key = _generateKey(target.path, target.scanMode);
    await scanTargetBox.put(key, target);
    debugPrint(
      '[ScannerPathRepository] Saved target: ${target.path} for mode: ${target.scanMode.name}',
    );
  }

  /// 快捷更新方法：仅更新指定目标的最后扫描时间
  Future<void> updateLastScannedAt(
    String path,
    ScanMode mode,
    int timestamp,
  ) async {
    final key = _generateKey(path, mode);
    final cached = scanTargetBox.get(key);
    if (cached != null) {
      final updated = cached.copyWith(lastScannedAt: timestamp);
      await scanTargetBox.put(key, updated);
      final activeTarget = scanTargetBox.get(activeKey);
      if (activeTarget != null &&
          activeTarget.path == path &&
          activeTarget.scanMode == mode) {
        await scanTargetBox.put(activeKey, updated);
      }
    }
  }

  /// 删除一个扫描目标，并联动清理该路径下产生的所有文件缓存
  Future<void> deleteTarget(String path, ScanMode mode) async {
    final key = _generateKey(path, mode);
    if (scanTargetBox.containsKey(key)) {
      await FileScannerStorage().clearByRootPath(mode, path);
      await scanTargetBox.delete(key);
      debugPrint(
        '[ScannerPathRepository] Deleted target and cleared caches for: $path',
      );
    }
  }

  Future<void> clearAllTargets() async {
    await scanTargetBox.clear();
    debugPrint('[ScannerPathRepository] Cleared absolutely all scan targets.');
  }

  /// 获取单个特定的扫描目标
  ScanTarget? getTarget(String path, ScanMode mode) {
    final key = _generateKey(path, mode);
    return scanTargetBox.get(key);
  }

  /// 获取所有的扫描目标列表
  /// 默认按照 [addedAt] 降序排列（最新添加的排在前面），方便 UI 列表渲染
  List<ScanTarget> getAllTargets() {
    return scanTargetBox.keys
        .where((k) => !k.toString().startsWith('active_'))
        .map((k) => scanTargetBox.get(k)!)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// 筛选出属于某个特定 [ScanMode] 的所有扫描目标
  /// 用于给不同的文件浏览页面（音频/视频/字幕）提供各自的根目录列表
  List<ScanTarget> getTargetsByMode(ScanMode mode) {
    return scanTargetBox.keys
        .where((k) => !k.toString().startsWith('active_'))
        .map((k) => scanTargetBox.get(k)!)
        .where((target) => target.scanMode == mode)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// 判断某个路径在指定模式下是否已经被添加过
  bool isPathExists(String path, ScanMode mode) {
    final key = _generateKey(path, mode);
    return scanTargetBox.containsKey(key);
  }
}
