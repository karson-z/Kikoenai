import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'file_node_library_index.dart';

class LocalScanExclusions {
  const LocalScanExclusions();

  static String normalize(String path) =>
      FileNodeLibraryIndex.normalizePath(path);

  static bool containsPath(String rule, String path) {
    final normalizedRule = normalize(rule).toLowerCase();
    final normalizedPath = normalize(path).toLowerCase();
    return normalizedPath == normalizedRule ||
        normalizedPath.startsWith('$normalizedRule/');
  }

  String _key(ScanMode mode, String rootPath) =>
      'local_scan_exclusions.${mode.name}.${Uri.encodeComponent(normalize(rootPath).toLowerCase())}';

  List<String> getRules(ScanMode mode, String rootPath) {
    final raw = AppStorage.settingsBox.get(_key(mode, rootPath));
    return raw is List ? raw.whereType<String>().toList() : const [];
  }

  bool isExcluded(ScanMode mode, String rootPath, String path) =>
      getRules(mode, rootPath).any((rule) => containsPath(rule, path));

  Future<void> add(
      ScanMode mode, String rootPath, Iterable<String> paths) async {
    final rules =
        {...getRules(mode, rootPath), ...paths.map(normalize)}.toList()..sort();
    await AppStorage.settingsBox.put(_key(mode, rootPath), rules);
  }

  Future<void> remove(
      ScanMode mode, String rootPath, Iterable<String> paths) async {
    final removed = paths.map((path) => normalize(path).toLowerCase()).toSet();
    final remaining = getRules(mode, rootPath)
        .where((rule) => !removed.contains(normalize(rule).toLowerCase()))
        .toList();
    await AppStorage.settingsBox.put(_key(mode, rootPath), remaining);
  }

  Future<void> moveRulesUnderPath(String oldPath, String newPath) async {
    final keys = AppStorage.settingsBox.keys
        .where(
            (key) => key is String && key.startsWith('local_scan_exclusions.'))
        .cast<String>()
        .toList();
    for (final key in keys) {
      final raw = AppStorage.settingsBox.get(key);
      if (raw is! List) continue;
      final rules = raw.whereType<String>().map((rule) {
        if (!containsPath(oldPath, rule)) return rule;
        return '${normalize(newPath)}${normalize(rule).substring(normalize(oldPath).length)}';
      }).toList();
      await AppStorage.settingsBox.put(key, rules);
    }
  }
}
