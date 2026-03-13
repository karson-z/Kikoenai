import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;
import '../../storage/hive_storage.dart';
import 'file_scanner_service.dart';

/// 文件扫描存储类
///
/// 负责与 Hive 数据库交互，持久化保存 [FileNode] 数据。
/// 采用单例模式，通过传入 [ScanMode] 参数来实现数据的命名空间隔离。
class FileScannerStorage {
  // --- 单例模式实现 ---
  FileScannerStorage._();
  static final FileScannerStorage _instance = FileScannerStorage._();
  factory FileScannerStorage() => _instance;

  /// 获取 Hive Box 引用
  Box<FileNode> get _box => AppStorage.scannerBox;

  // --- 私有辅助方法 ---

  /// 生成带有模式隔离的独立 Key (Namespace)
  String _generateIsolatedKey(ScanMode mode, String originalKey) {
    return '${mode.name}_$originalKey';
  }

  /// 检查 Hive 中的 Key 是否属于指定的扫描模式
  bool _isModeKey(ScanMode mode, dynamic key) {
    return key is String && key.startsWith('${mode.name}_');
  }

  // --- 模式特定的操作 (需传入 ScanMode) ---

  /// 根据根路径获取指定模式下缓存的所有文件节点
  List<FileNode> getNodesByRootPath(ScanMode mode, String rootPath) {
    if (_box.isEmpty) return [];

    final posix = p.Context(style: p.Style.posix);
    final normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));

    return _box.toMap().entries
        .where((e) => _isModeKey(mode, e.key))
        .map((e) => e.value)
        .where((node) {
      if (node.mediaStreamUrl == null) return false;
      final nodePath = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      return nodePath == normalizedRoot || posix.isWithin(normalizedRoot, nodePath);
    }).toList();
  }

  /// 根据 Key 获取指定模式下的单个节点
  FileNode? getNode(ScanMode mode, String key) {
    return _box.get(_generateIsolatedKey(mode, key));
  }

  /// 获取指定模式下所有缓存的文件节点
  List<FileNode> getAllByMode(ScanMode mode) {
    return _box.toMap().entries
        .where((e) => _isModeKey(mode, e.key))
        .map((e) => e.value)
        .toList();
  }

  /// 批量保存或更新指定模式的节点
  Future<void> saveNodes(ScanMode mode, List<FileNode> nodes) async {
    if (nodes.isEmpty) return;

    final Map<String, FileNode> map = {};
    for (var node in nodes) {
      if (node.keyId.isNotEmpty) {
        map[_generateIsolatedKey(mode, node.keyId)] = node;
      }
    }
    await _box.putAll(map);
    debugPrint('[FileScannerStorage] (${mode.name}) 成功保存/更新了 ${nodes.length} 个节点。');
  }

  /// 保存指定模式的单个节点
  Future<void> saveNode(ScanMode mode, FileNode node) async {
    if (node.keyId.isNotEmpty) {
      await _box.put(_generateIsolatedKey(mode, node.keyId), node);
    }
  }

  /// 批量删除指定模式的节点
  Future<void> deleteNodes(ScanMode mode, List<String> keys) async {
    if (keys.isEmpty) return;
    final keysToDelete = keys.map((k) => _generateIsolatedKey(mode, k)).toList();
    await _box.deleteAll(keysToDelete);
    debugPrint('[FileScannerStorage] (${mode.name}) 成功删除了 ${keysToDelete.length} 个失效节点。');
  }

  /// 清空指定根路径下的所有相关模式的节点
  Future<void> clearByRootPath(ScanMode mode, String rootPath) async {
    final posix = p.Context(style: p.Style.posix);
    final normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));

    final keysToDelete = _box.toMap().entries.where((e) {
      if (!_isModeKey(mode, e.key)) return false;

      final node = e.value;
      if (node.mediaStreamUrl == null) return false;

      final nodePath = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      return nodePath == normalizedRoot || posix.isWithin(normalizedRoot, nodePath);
    }).map((e) => e.key).toList();

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
      debugPrint('[FileScannerStorage] (${mode.name}) 成功清理了 ${keysToDelete.length} 个属于 $normalizedRoot 的节点缓存。');
    }
  }

  /// 清空指定扫描模式下的所有数据
  Future<void> clearByMode(ScanMode mode) async {
    final keysToDelete = _box.keys.where((k) => _isModeKey(mode, k)).toList();
    await _box.deleteAll(keysToDelete);
    debugPrint('[FileScannerStorage] (${mode.name}) 已清空该模式下的全部缓存数据。');
  }

  // --- 全局跨模式操作 (不需指定 ScanMode) ---

  /// 获取数据库中所有扫描模式下(音频、视频、字幕)的全部缓存文件节点
  List<FileNode> getAllAcrossModes() {
    return _box.values.toList();
  }

  /// 危险操作：无视模式隔离，清空整个扫描器数据库的所有数据
  Future<void> clearAbsolutelyAll() async {
    await _box.clear();
    debugPrint('[FileScannerStorage] 已彻底清空所有模式的缓存数据。');
  }

  /// 全局方法：根据作品 ID，从全局扁平缓存中捞取并重组出该作品的专属文件树
  FileNode? getWorkFileTreeLocally(int workId) {
    final targetRj = "RJ$workId".toUpperCase();
    final targetRj0 = "RJ0$workId".toUpperCase();

    final allNodes = getAllAcrossModes();

    final rootFolders = allNodes.where((node) {
      final nodeRj = node.rjCode?.toUpperCase() ?? '';
      return node.isFolder && (nodeRj == targetRj || nodeRj == targetRj0);
    }).toList();

    if (rootFolders.isEmpty) return null;

    final rootFolder = rootFolders.first;
    final rawRootPath = rootFolder.mediaStreamUrl;
    if (rawRootPath == null) return null;

    final posix = p.Context(style: p.Style.posix);
    final rootPath = posix.normalize(rawRootPath.replaceAll('\\', '/'));

    final Map<String, FileNode> uniqueDescendants = {};
    for (var node in allNodes) {
      if (node.mediaStreamUrl == null) continue;
      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      if (posix.isWithin(rootPath, path)) {
        uniqueDescendants[path] = node;
      }
    }

    final descendantNodes = uniqueDescendants.values.toList();

    Map<String, List<FileNode>> childrenMap = {};
    for (final node in descendantNodes) {
      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      final parentPath = posix.dirname(path);
      childrenMap.putIfAbsent(parentPath, () => []).add(node);
    }

    FileNode assembleTree(FileNode node) {
      if (!node.isFolder) return node;

      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      final children = childrenMap[path] ?? [];
      final assembledChildren = children.map((c) => assembleTree(c)).toList();

      assembledChildren.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      return node.copyWith(children: assembledChildren);
    }

    final rootDirectChildren = childrenMap[rootPath] ?? [];
    final finalTreeNodes = rootDirectChildren.map((c) => assembleTree(c)).toList();

    finalTreeNodes.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return rootFolder.copyWith(children: finalTreeNodes);
  }

  /// 全局方法：跨越所有模式，同步更新特定节点的状态
  Future<void> updateNodeStatusByKeyGlobally(String keyId, NodeStatus newStatus) async {
    final updates = <String, FileNode>{};

    for (final mode in ScanMode.values) {
      final isolatedKey = _generateIsolatedKey(mode, keyId);
      final existingNode = _box.get(isolatedKey);

      if (existingNode != null) {
        updates[isolatedKey] = existingNode.copyWith(nodeStatus: newStatus);
      }
    }

    if (updates.isNotEmpty) {
      await _box.putAll(updates);
      debugPrint('[FileScannerStorage] (全局) 已同步更新节点 $keyId 的状态为 ${newStatus.name}');
    }
  }
}