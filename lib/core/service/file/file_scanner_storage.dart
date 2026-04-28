import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;
import '../../storage/hive_storage.dart';
import 'file_scanner_service.dart';

enum RootScanStatus {
  success,
  error,
  cancelled,
}

class RootScanMeta {
  static const Object _unset = Object();

  final DateTime? lastSuccessfulScanAt;
  final DateTime? lastAttemptAt;
  final RootScanStatus? lastScanStatus;
  final int cachedFileCount;
  final bool isDirty;

  const RootScanMeta({
    this.lastSuccessfulScanAt,
    this.lastAttemptAt,
    this.lastScanStatus,
    this.cachedFileCount = 0,
    this.isDirty = false,
  });

  factory RootScanMeta.fromMap(Map<dynamic, dynamic> map) {
    return RootScanMeta(
      lastSuccessfulScanAt: _dateFromMillis(map['lastSuccessfulScanAt']),
      lastAttemptAt: _dateFromMillis(map['lastAttemptAt']),
      lastScanStatus: _statusFromName(map['lastScanStatus'] as String?),
      cachedFileCount: (map['cachedFileCount'] as num?)?.toInt() ?? 0,
      isDirty: map['isDirty'] == true,
    );
  }

  static DateTime? _dateFromMillis(dynamic value) {
    final millis = (value as num?)?.toInt();
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static RootScanStatus? _statusFromName(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final status in RootScanStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'lastSuccessfulScanAt': lastSuccessfulScanAt?.millisecondsSinceEpoch,
      'lastAttemptAt': lastAttemptAt?.millisecondsSinceEpoch,
      'lastScanStatus': lastScanStatus?.name,
      'cachedFileCount': cachedFileCount,
      'isDirty': isDirty,
    };
  }

  RootScanMeta copyWith({
    Object? lastSuccessfulScanAt = _unset,
    Object? lastAttemptAt = _unset,
    Object? lastScanStatus = _unset,
    int? cachedFileCount,
    bool? isDirty,
  }) {
    return RootScanMeta(
      lastSuccessfulScanAt: identical(lastSuccessfulScanAt, _unset)
          ? this.lastSuccessfulScanAt
          : lastSuccessfulScanAt as DateTime?,
      lastAttemptAt: identical(lastAttemptAt, _unset)
          ? this.lastAttemptAt
          : lastAttemptAt as DateTime?,
      lastScanStatus: identical(lastScanStatus, _unset)
          ? this.lastScanStatus
          : lastScanStatus as RootScanStatus?,
      cachedFileCount: cachedFileCount ?? this.cachedFileCount,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class FileScannerStorage {
  FileScannerStorage._();
  static final FileScannerStorage _instance = FileScannerStorage._();
  factory FileScannerStorage() => _instance;

  static const String _metaPrefix = 'scan_meta';
  static const String _indexPrefix = 'scan_index';

  final p.Context _posix = p.Context(style: p.Style.posix);

  Box<FileNode> get _box => AppStorage.scannerBox;
  Box<dynamic> get _settingsBox => AppStorage.settingsBox;

  String _computeMd5(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return md5.convert(utf8.encode(normalized)).toString();
  }

  String _normalizeComparablePath(String path) {
    var normalized = _posix.normalize(path.replaceAll('\\', '/'));
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.toLowerCase();
  }

  String _generateIsolatedKey(ScanMode mode, String originalPath) {
    final pathMd5 = _computeMd5(originalPath);
    return '${mode.name}_$pathMd5';
  }

  String _metaKey(ScanMode mode, String rootPath) {
    return '${_metaPrefix}_${mode.name}_${_computeMd5(rootPath)}';
  }

  String _indexKey(ScanMode mode, String rootPath) {
    return '${_indexPrefix}_${mode.name}_${_computeMd5(rootPath)}';
  }

  bool _isModeKey(ScanMode mode, dynamic key) {
    return key is String && key.startsWith('${mode.name}_');
  }

  bool _isNodeUnderRoot(String? nodePath, String normalizedRoot) {
    if (nodePath == null || nodePath.isEmpty) return false;
    final normalizedNode = _normalizeComparablePath(nodePath);
    return normalizedNode == normalizedRoot ||
        _posix.isWithin(normalizedRoot, normalizedNode);
  }

  List<String>? getRootIndex(ScanMode mode, String rootPath) {
    final raw = _settingsBox.get(_indexKey(mode, rootPath));
    if (raw is! List) return null;
    return raw.cast<String>();
  }

  bool hasRootIndex(ScanMode mode, String rootPath) {
    return _settingsBox.containsKey(_indexKey(mode, rootPath));
  }

  RootScanMeta? getRootMeta(ScanMode mode, String rootPath) {
    final raw = _settingsBox.get(_metaKey(mode, rootPath));
    if (raw is! Map) return null;
    return RootScanMeta.fromMap(raw);
  }

  Future<void> saveRootMeta(
    ScanMode mode,
    String rootPath,
    RootScanMeta meta,
  ) async {
    await _settingsBox.put(_metaKey(mode, rootPath), meta.toMap());
  }

  Future<void> markRootDirty(
    ScanMode mode,
    String rootPath, {
    required bool isDirty,
  }) async {
    final current = getRootMeta(mode, rootPath) ?? const RootScanMeta();
    await saveRootMeta(
      mode,
      rootPath,
      current.copyWith(isDirty: isDirty),
    );
  }

  Future<void> replaceRootIndex(
    ScanMode mode,
    String rootPath,
    List<FileNode> nodes,
  ) async {
    final keys = nodes
        .map((node) => node.keyId)
        .where((path) => path.isNotEmpty)
        .map((path) => _generateIsolatedKey(mode, path))
        .toSet()
        .toList();
    await _settingsBox.put(_indexKey(mode, rootPath), keys);
  }

  Future<void> clearRootArtifacts(ScanMode mode, String rootPath) async {
    await Future.wait([
      _settingsBox.delete(_metaKey(mode, rootPath)),
      _settingsBox.delete(_indexKey(mode, rootPath)),
    ]);
  }

  List<FileNode> _scanNodesByRootPath(ScanMode mode, String rootPath) {
    if (_box.isEmpty) return [];
    final normalizedRoot = _normalizeComparablePath(rootPath);

    return _box.toMap().entries
        .where((entry) => _isModeKey(mode, entry.key))
        .map((entry) => entry.value)
        .where((node) => _isNodeUnderRoot(node.mediaStreamUrl, normalizedRoot))
        .toList();
  }

  List<FileNode> getNodesByRootPath(
    ScanMode mode,
    String rootPath, {
    bool preferIndex = true,
  }) {
    if (_box.isEmpty) return [];

    if (preferIndex) {
      final index = getRootIndex(mode, rootPath);
      if (index != null) {
        final nodes = index
            .map((isolatedKey) => _box.get(isolatedKey))
            .whereType<FileNode>()
            .toList();

        if (nodes.length != index.length) {
          unawaited(replaceRootIndex(mode, rootPath, nodes));
        }
        return nodes;
      }
    }

    final nodes = _scanNodesByRootPath(mode, rootPath);
    if (nodes.isNotEmpty) {
      unawaited(replaceRootIndex(mode, rootPath, nodes));
    }
    return nodes;
  }

  FileNode? getNode(ScanMode mode, String path) {
    return _box.get(_generateIsolatedKey(mode, path));
  }

  List<FileNode> getAllByMode(ScanMode mode) {
    return _box.toMap().entries
        .where((entry) => _isModeKey(mode, entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  Future<void> saveNodes(ScanMode mode, List<FileNode> nodes) async {
    if (nodes.isEmpty) return;

    final map = <String, FileNode>{};
    for (final node in nodes) {
      if (node.keyId.isEmpty) continue;
      final pathMd5 = _computeMd5(node.keyId);
      map['${mode.name}_$pathMd5'] = node.copyWith(hash: pathMd5);
    }

    if (map.isEmpty) return;
    await _box.putAll(map);
    debugPrint(
      '[FileScannerStorage] (${mode.name}) 成功保存/更新了 ${map.length} 个 MD5 节点。',
    );
  }

  Future<void> saveNode(ScanMode mode, FileNode node) async {
    if (node.keyId.isEmpty) return;
    final pathMd5 = _computeMd5(node.keyId);
    await _box.put(
      '${mode.name}_$pathMd5',
      node.copyWith(hash: pathMd5),
    );
  }

  Future<void> deleteNodes(ScanMode mode, List<String> paths) async {
    if (paths.isEmpty) return;
    final keysToDelete = paths
        .map((path) => _generateIsolatedKey(mode, path))
        .toList();
    await _box.deleteAll(keysToDelete);
    debugPrint(
      '[FileScannerStorage] (${mode.name}) 成功删除了 ${keysToDelete.length} 个失效 MD5 节点。',
    );
  }

  Future<void> clearByRootPath(
    ScanMode mode,
    String rootPath, {
    bool preferIndex = true,
  }) async {
    final index = preferIndex ? getRootIndex(mode, rootPath) : null;
    if (preferIndex && index != null) {
      if (index.isNotEmpty) {
        await _box.deleteAll(index);
      }
      await clearRootArtifacts(mode, rootPath);
      debugPrint(
        '[FileScannerStorage] (${mode.name}) 已按索引清理根路径缓存: $rootPath',
      );
      return;
    }

    final nodes = _scanNodesByRootPath(mode, rootPath);
    final keysToDelete = nodes
        .map((node) => node.keyId)
        .where((path) => path.isNotEmpty)
        .map((path) => _generateIsolatedKey(mode, path))
        .toList();

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
      debugPrint(
        '[FileScannerStorage] (${mode.name}) 成功清理了 ${keysToDelete.length} 个属于 $rootPath 的 MD5 缓存。',
      );
    }
    await clearRootArtifacts(mode, rootPath);
  }

  Future<void> clearByMode(ScanMode mode) async {
    final scannerKeys = _box.keys.where((key) => _isModeKey(mode, key)).toList();
    if (scannerKeys.isNotEmpty) {
      await _box.deleteAll(scannerKeys);
    }

    final settingsKeys = _settingsBox.keys
        .whereType<String>()
        .where(
          (key) =>
              key.startsWith('${_metaPrefix}_${mode.name}_') ||
              key.startsWith('${_indexPrefix}_${mode.name}_'),
        )
        .toList();
    if (settingsKeys.isNotEmpty) {
      await _settingsBox.deleteAll(settingsKeys);
    }

    debugPrint('[FileScannerStorage] (${mode.name}) 已清空该模式下的全部缓存与索引数据。');
  }

  List<FileNode> getAllAcrossModes() {
    return _box.values.toList();
  }

  Future<void> clearAbsolutelyAll() async {
    await _box.clear();
    final scanSettingsKeys = _settingsBox.keys
        .whereType<String>()
        .where(
          (key) => key.startsWith(_metaPrefix) || key.startsWith(_indexPrefix),
        )
        .toList();
    if (scanSettingsKeys.isNotEmpty) {
      await _settingsBox.deleteAll(scanSettingsKeys);
    }
    debugPrint('[FileScannerStorage] 已彻底清空所有模式的缓存与索引数据。');
  }

  FileNode? getWorkFileTreeLocally(int workId) {
    final targetRj = 'RJ$workId'.toUpperCase();
    final targetRj0 = 'RJ0$workId'.toUpperCase();

    final allNodes = getAllAcrossModes();
    final rootFolders = allNodes.where((node) {
      final nodeRj = node.rjCode?.toUpperCase() ?? '';
      return node.isFolder && (nodeRj == targetRj || nodeRj == targetRj0);
    }).toList();

    if (rootFolders.isEmpty) return null;

    final rootFolder = rootFolders.first;
    final rawRootPath = rootFolder.mediaStreamUrl;
    if (rawRootPath == null) return null;

    final rootPath = _posix.normalize(rawRootPath.replaceAll('\\', '/'));

    final uniqueDescendants = <String, FileNode>{};
    for (final node in allNodes) {
      if (node.mediaStreamUrl == null) continue;
      final path = _posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      if (_posix.isWithin(rootPath, path)) {
        uniqueDescendants[path] = node;
      }
    }

    final descendantNodes = uniqueDescendants.values.toList();
    final childrenMap = <String, List<FileNode>>{};
    for (final node in descendantNodes) {
      final path = _posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      final parentPath = _posix.dirname(path);
      childrenMap.putIfAbsent(parentPath, () => []).add(node);
    }

    FileNode assembleTree(FileNode node) {
      if (!node.isFolder) return node;

      final path = _posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      final children = childrenMap[path] ?? [];
      final assembledChildren = children.map(assembleTree).toList();

      assembledChildren.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      return node.copyWith(children: assembledChildren);
    }

    final rootDirectChildren = childrenMap[rootPath] ?? [];
    final finalTreeNodes = rootDirectChildren.map(assembleTree).toList();
    finalTreeNodes.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return rootFolder.copyWith(children: finalTreeNodes);
  }

  Future<void> updateNodeStatusByKeyGlobally(
    String path,
    NodeStatus newStatus,
  ) async {
    final updates = <String, FileNode>{};

    for (final mode in ScanMode.values) {
      final isolatedKey = _generateIsolatedKey(mode, path);
      final existingNode = _box.get(isolatedKey);
      if (existingNode != null) {
        updates[isolatedKey] = existingNode.copyWith(nodeStatus: newStatus);
      }
    }

    if (updates.isNotEmpty) {
      await _box.putAll(updates);
      debugPrint('[FileScannerStorage] (全局) 已同步更新路径 MD5 节点的状态为 ${newStatus.name}');
    }
  }
}
