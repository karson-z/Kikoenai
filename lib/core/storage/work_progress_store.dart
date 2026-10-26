import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

/// 将业务作用域与 Hive 物理键分开，路径再长也只写入 68 字节的键。
class WorkProgressStore {
  const WorkProgressStore(this.box);

  final Box<WorkProgressPoint> box;

  static String keyForScope(String scopeKey) =>
      'wp1:${sha256.convert(utf8.encode(scopeKey))}';

  WorkProgressPoint? _legacyPoint(String scopeKey) {
    // 旧版直接用作用域作键；Hive 的磁盘键长度只有一个字节。
    if (scopeKey.length > 255 || utf8.encode(scopeKey).length > 255) {
      return null;
    }
    final point = box.get(scopeKey);
    return point?.scopeKey == scopeKey ? point : null;
  }

  WorkProgressPoint? getByScope(String scopeKey) {
    final point = box.get(keyForScope(scopeKey));
    final legacy = _legacyPoint(scopeKey);
    if (point == null) return legacy;
    return legacy != null && legacy.updatedAt > point.updatedAt
        ? legacy
        : point;
  }

  Future<void> save(WorkProgressPoint point) async {
    await box.put(keyForScope(point.scopeKey), point);
    // 先确认新键写入成功，再清理同一作用域的旧键，避免丢失已有进度。
    if (_legacyPoint(point.scopeKey) != null) {
      await box.delete(point.scopeKey);
    }
  }

  Future<void> delete(String scopeKey) async {
    await box.delete(keyForScope(scopeKey));
    if (_legacyPoint(scopeKey) != null) {
      await box.delete(scopeKey);
    }
  }
}
