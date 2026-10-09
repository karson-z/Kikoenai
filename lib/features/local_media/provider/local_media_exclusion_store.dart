import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../model/local_media_exclusion.dart';

/// 本地媒体排除记录的读写。
///
/// 每条记录单独存在独立的本地媒体排除 Box 中。
/// 匹配按规范化后的相对路径分段比较，避免只凭字符串前缀误伤同名前缀的其他目录。
class LocalMediaExclusionStore {
  LocalMediaExclusionStore(this._box);

  factory LocalMediaExclusionStore.app() {
    return LocalMediaExclusionStore(AppStorage.localMediaExclusionBox);
  }

  final Box<dynamic> _box;

  List<LocalMediaExclusion> readAll() {
    return _box.values
        .map(LocalMediaExclusion.fromJson)
        .whereType<LocalMediaExclusion>()
        .toList(growable: false);
  }

  List<LocalMediaExclusion> readForRoot(String rootPath) {
    final normalizedRoot = NodeFolder.normalizePath(rootPath);
    return readAll()
        .where((entry) => entry.rootPath == normalizedRoot)
        .toList(growable: false);
  }

  Future<void> addAll(List<LocalMediaExclusion> entries) async {
    if (entries.isEmpty) return;
    final current = readAll();
    final byKey = {for (final entry in current) entry.storageKey: entry};
    for (final entry in entries) {
      byKey[entry.storageKey] = entry;
    }
    await _write(byKey.values.toList(growable: false));
  }

  Future<void> remove(LocalMediaExclusion entry) async {
    final next = readAll()
        .where((item) => item.storageKey != entry.storageKey)
        .toList(growable: false);
    await _write(next);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> _write(List<LocalMediaExclusion> entries) async {
    await _box.clear();
    await _box.putAll({
      for (final entry in entries) entry.storageKey: entry.toJson(),
    });
  }

  /// 返回 [absolutePath] 相对 [rootPath] 的规范化路径。
  ///
  /// 路径不在根目录下时返回 `null`。
  static String? relativePath(String rootPath, String absolutePath) {
    final root = NodeFolder.normalizePath(rootPath);
    final target = NodeFolder.normalizePath(absolutePath);
    final rootKey = root.toLowerCase();
    final targetKey = target.toLowerCase();
    if (targetKey == rootKey) return '';
    if (!targetKey.startsWith('$rootKey/')) return null;
    return target.substring(root.length + 1);
  }

  /// 文件或文件夹是否命中排除记录，或位于已排除文件夹内部。
  static bool isExcluded({
    required String rootPath,
    required String absolutePath,
    required bool isFolder,
    required List<LocalMediaExclusion> entries,
  }) {
    final relative = relativePath(rootPath, absolutePath);
    if (relative == null || relative.isEmpty) return false;
    final segments = relative.split('/');
    for (final entry in entries) {
      if (entry.rootPath != NodeFolder.normalizePath(rootPath)) continue;
      final excluded = entry.relativePath.split('/');
      if (excluded.isEmpty || excluded.first.isEmpty) continue;
      if (segments.length < excluded.length) continue;
      final samePrefix = List.generate(
        excluded.length,
        (index) => segments[index].toLowerCase() == excluded[index].toLowerCase(),
      ).every((matches) => matches);
      if (!samePrefix) continue;
      if (entry.isFolder) return true;
      if (segments.length == excluded.length && !isFolder) return true;
    }
    return false;
  }
}
