import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;
import '../../storage/hive_storage.dart';
import 'file_scanner_service.dart';

/// 文件扫描存储类
///
/// 负责与 Hive 数据库交互，持久化保存 [FileNode] 数据。
/// - 实例方法：引入了 [ScanMode] 进行数据隔离，不同的扫描模式操作各自独立的数据集。
/// - 静态方法：提供跨越模式边界的全局聚合与查询能力。
class FileScannerStorage {
  final ScanMode scanMode;

  // 为每种扫描模式维护一个独立的实例 (Multiton)
  static final Map<ScanMode, FileScannerStorage> _instances = {};

  FileScannerStorage._internal(this.scanMode);

  /// 工厂构造函数：根据传入的 ScanMode 返回对应的存储实例
  factory FileScannerStorage(ScanMode mode) {
    return _instances.putIfAbsent(mode, () => FileScannerStorage._internal(mode));
  }

  /// 获取当前实例的 Hive Box 引用
  Box<FileNode> get _box => AppStorage.scannerBox;

  /// 生成带有模式隔离的独立 Key (Namespace)
  String _generateIsolatedKey(String originalKey) {
    return '${scanMode.name}_$originalKey';
  }

  /// 检查 Hive 中的 Key 是否属于当前扫描模式
  bool _isCurrentModeKey(dynamic key) {
    return key is String && key.startsWith('${scanMode.name}_');
  }


  /// 根据根路径获取缓存的所有文件节点
  List<FileNode> getNodesByRootPath(String rootPath) {
    if (_box.isEmpty) return [];

    final posix = p.Context(style: p.Style.posix);
    final normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));

    return _box.toMap().entries
        .where((e) => _isCurrentModeKey(e.key))
        .map((e) => e.value)
        .where((node) {
      if (node.mediaStreamUrl == null) return false;
      final nodePath = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      return nodePath == normalizedRoot || posix.isWithin(normalizedRoot, nodePath);
    }).toList();
  }

  /// 根据 Key 获取单个节点
  FileNode? getNode(String key) {
    return _box.get(_generateIsolatedKey(key));
  }

  /// 获取当前模式下所有缓存的文件节点
  List<FileNode> getAll() {
    return _box.toMap().entries
        .where((e) => _isCurrentModeKey(e.key))
        .map((e) => e.value)
        .toList();
  }

  /// 批量保存或更新节点
  Future<void> saveNodes(List<FileNode> nodes) async {
    if (nodes.isEmpty) return;

    final Map<String, FileNode> map = {};
    for (var node in nodes) {
      if (node.keyId.isNotEmpty) {
        map[_generateIsolatedKey(node.keyId)] = node;
      }
    }
    await _box.putAll(map);
    debugPrint('[FileScannerStorage] (${scanMode.name}) 成功保存/更新了 ${nodes.length} 个节点。');
  }

  /// 保存单个节点
  Future<void> saveNode(FileNode node) async {
    if (node.keyId.isNotEmpty) {
      await _box.put(_generateIsolatedKey(node.keyId), node);
    }
  }

  /// 批量删除节点
  Future<void> deleteNodes(List<String> keys) async {
    if (keys.isEmpty) return;
    final keysToDelete = keys.map((k) => _generateIsolatedKey(k)).toList();
    await _box.deleteAll(keysToDelete);
    debugPrint('[FileScannerStorage] (${scanMode.name}) 成功删除了 ${keysToDelete.length} 个失效节点。');
  }

  /// 清空指定根路径下的所有当前模式相关的节点
  Future<void> clearByRootPath(String rootPath) async {
    final posix = p.Context(style: p.Style.posix);
    final normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));

    final keysToDelete = _box.toMap().entries.where((e) {
      if (!_isCurrentModeKey(e.key)) return false;

      final node = e.value;
      if (node.mediaStreamUrl == null) return false;

      final nodePath = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      return nodePath == normalizedRoot || posix.isWithin(normalizedRoot, nodePath);
    }).map((e) => e.key).toList();

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
      debugPrint('[FileScannerStorage] (${scanMode.name}) 成功清理了 ${keysToDelete.length} 个属于 $normalizedRoot 的节点缓存。');
    }
  }

  /// 清空当前扫描模式下的所有数据
  Future<void> clearAll() async {
    final keysToDelete = _box.keys.where((k) => _isCurrentModeKey(k)).toList();
    await _box.deleteAll(keysToDelete);
    debugPrint('[FileScannerStorage] (${scanMode.name}) 已清空当前模式下的全部缓存数据。');
  }


  /// 静态 Box 引用，供静态方法使用
  static Box<FileNode> get _staticBox => AppStorage.scannerBox;

  /// 全局静态方法：获取数据库中所有扫描模式下(音频、视频、字幕)的全部缓存文件节点
  static List<FileNode> getAllAcrossModes() {
    return _staticBox.values.toList();
  }

  /// 危险操作：无视模式隔离，清空整个扫描器数据库的所有数据
  static Future<void> clearAbsolutelyAll() async {
    await _staticBox.clear();
    debugPrint('[FileScannerStorage] 已彻底清空所有模式的缓存数据。');
  }

  /// 全局静态方法：根据作品 ID，从全局扁平缓存中捞取并重组出该作品的专属文件树
  ///
  /// 场景：聚合音频、视频、字幕文件，构建一棵完整的作品媒体树。
  static FileNode? getWorkFileTreeLocally(int workId) {
    final targetRj = "RJ$workId".toUpperCase();
    final targetRj0 = "RJ0$workId".toUpperCase();

    // 提取全部模式的数据
    final allNodes = getAllAcrossModes();

    // 1. 寻找拥有该 RJ 码的根文件夹
    final rootFolders = allNodes.where((node) {
      final nodeRj = node.rjCode?.toUpperCase() ?? '';
      return node.isFolder && (nodeRj == targetRj || nodeRj == targetRj0);
    }).toList();

    if (rootFolders.isEmpty) return null;

    // 可能存在多个模式都生成了该根文件夹节点的情况，取第一个即可作为壳子
    final rootFolder = rootFolders.first;
    final rawRootPath = rootFolder.mediaStreamUrl;
    if (rawRootPath == null) return null;

    final posix = p.Context(style: p.Style.posix);
    final rootPath = posix.normalize(rawRootPath.replaceAll('\\', '/'));

    // 2. 捞取所有属于该文件夹的子孙节点
    // 为了防止多个扫描模式生成了同名的子文件夹导致重复，这里可以使用 Set 或对 mediaStreamUrl 去重
    final Map<String, FileNode> uniqueDescendants = {};
    for (var node in allNodes) {
      if (node.mediaStreamUrl == null) continue;
      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      if (posix.isWithin(rootPath, path)) {
        // 如果是文件夹，优先保留已存在缓存的（或者简单的覆盖，因为同一路径的文件夹节点作用一致）
        // 如果是文件，由于后缀或类型不同，理论上路径不会冲突
        uniqueDescendants[path] = node;
      }
    }

    final descendantNodes = uniqueDescendants.values.toList();

    // 3. 构建父子级映射字典 (Map)
    Map<String, List<FileNode>> childrenMap = {};
    for (final node in descendantNodes) {
      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      final parentPath = posix.dirname(path);
      childrenMap.putIfAbsent(parentPath, () => []).add(node);
    }

    // 4. 定义递归算法，内存中重组树形结构
    FileNode assembleTree(FileNode node) {
      if (!node.isFolder) return node;

      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      final children = childrenMap[path] ?? [];
      final assembledChildren = children.map((c) => assembleTree(c)).toList();

      // UI 排序：文件夹优先，同类按字母升序
      assembledChildren.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      return node.copyWith(children: assembledChildren);
    }

    // 5. 触发顶层组装并返回最终副本
    final rootDirectChildren = childrenMap[rootPath] ?? [];
    final finalTreeNodes = rootDirectChildren.map((c) => assembleTree(c)).toList();

    finalTreeNodes.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return rootFolder.copyWith(children: finalTreeNodes);
  }
  /// 全局静态方法：跨越所有模式，同步更新特定节点的状态
  ///
  /// 场景：爬虫在后台工作时，不需要关心当前节点属于音频还是视频。
  /// 它只需要通过这个方法，把所有模式下路径相同的节点状态统一更新即可。
  static Future<void> updateNodeStatusByKeyGlobally(String keyId, NodeStatus newStatus) async {
    final updates = <String, FileNode>{};

    // 遍历所有枚举的 ScanMode (音频、视频、字幕)
    for (final mode in ScanMode.values) {
      final isolatedKey = '${mode.name}_$keyId';
      final existingNode = _staticBox.get(isolatedKey);

      // 如果在这个模式下找到了该节点，就为它更新状态
      if (existingNode != null) {
        updates[isolatedKey] = existingNode.copyWith(nodeStatus: newStatus);
      }
    }

    if (updates.isNotEmpty) {
      await _staticBox.putAll(updates);
      debugPrint('[FileScannerStorage] (全局) 已同步更新节点 $keyId 的状态为 ${newStatus.name}');
    }
  }
}