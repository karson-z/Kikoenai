import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;

import '../../storage/hive_storage.dart';

/// 文件扫描存储类 (单例)
///
/// 负责与 Hive 数据库交互，持久化保存 [FileNode] 数据。
/// 在处理所有路径查找、比对、删除时，统一采用 POSIX 规范（强制使用 '/'），
/// 以解决 Windows('\') 与 Android/iOS/macOS('/') 跨平台路径分隔符导致的匹配失败问题。
class FileScannerStorage {
  static final FileScannerStorage _instance = FileScannerStorage._internal();
  FileScannerStorage._internal();
  factory FileScannerStorage() => _instance;

  /// 获取 Hive Box 引用
  Box<FileNode> get _box => AppStorage.scannerBox;

  /// 根据根路径获取缓存的所有文件节点 (已修复安全匹配漏洞)
  ///
  /// 场景：页面进入时，立即加载指定路径下的缓存显示给用户 (Cache-First 策略)。
  /// [rootPath] 目标文件夹的绝对路径。
  List<FileNode> getNodesByRootPath(String rootPath) {
    if (_box.isEmpty) return [];

    // 1. 创建统一的 POSIX 路径处理器并标准化传入的根路径
    final posix = p.Context(style: p.Style.posix);
    final normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));

    return _box.values.where((node) {
      if (node.mediaStreamUrl == null) return false;

      // 2. 将缓存中的节点路径也彻底标准化
      final nodePath = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));

      // 3. 安全匹配：要么是根目录节点本身，要么是其合法的内部子节点
      return nodePath == normalizedRoot || posix.isWithin(normalizedRoot, nodePath);
    }).toList();
  }

  /// 根据 Key 获取单个节点
  ///
  /// 场景：增量扫描时，比对底层文件系统的新旧节点的修改时间 (lastModified)。
  FileNode? getNode(String key) {
    return _box.get(key);
  }

  /// 获取数据库中所有缓存的文件节点
  List<FileNode> getAll() {
    return _box.values.toList();
  }

  /// 批量保存或更新节点
  ///
  /// 场景：Worker 扫描并发现新文件、状态变更、或文件修改后，批量写入 Hive。
  /// 使用 `putAll` 替代循环 `put`，大幅提升 I/O 性能。
  Future<void> saveNodes(List<FileNode> nodes) async {
    if (nodes.isEmpty) return;

    final Map<String, FileNode> map = {};
    for (var node in nodes) {
      if (node.keyId.isNotEmpty) {
        map[node.keyId] = node;
      }
    }
    await _box.putAll(map);
    debugPrint('[FileScannerStorage] 成功保存/更新了 ${nodes.length} 个节点。');
  }

  /// 保存单个节点
  Future<void> saveNode(FileNode node) async {
    if (node.keyId.isNotEmpty) {
      await _box.put(node.keyId, node);
    }
  }

  /// 批量删除节点
  ///
  /// 场景：Worker 增量扫描结束后，发现某些文件在物理磁盘上已不存在，从缓存中将其抹除。
  Future<void> deleteNodes(List<String> keys) async {
    if (keys.isEmpty) return;
    await _box.deleteAll(keys);
    debugPrint('[FileScannerStorage] 成功删除了 ${keys.length} 个失效节点。');
  }

  /// 根据作品 ID，从全局扁平缓存中捞取并重组出该作品的专属文件树
  ///
  /// 场景：从“已解析”列表跳转到专辑详情页时，跨目录提取内存中已有的完整文件树层级。
  /// [workId] 作品的数字 ID (例如 12345)。
  FileNode? getWorkFileTreeLocally(int workId) {
    final targetRj = "RJ$workId".toUpperCase();
    final targetRj0 = "RJ0$workId".toUpperCase();

    final allNodes = getAll();

    // 1. 寻找拥有该 RJ 码的根文件夹
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

    // 2. 捞取所有属于该文件夹的子孙节点
    final descendantNodes = allNodes.where((node) {
      if (node.mediaStreamUrl == null) return false;
      final path = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      return posix.isWithin(rootPath, path);
    }).toList();

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

  /// 清空指定根路径下的所有缓存及关联节点
  ///
  /// 场景：用户在路径管理界面点击“移除此路径”时，同步清理数据库，防止产生僵尸数据。
  Future<void> clearByRootPath(String rootPath) async {
    final posix = p.Context(style: p.Style.posix);
    final normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));

    final keysToDelete = _box.values.where((node) {
      if (node.mediaStreamUrl == null) return false;
      final nodePath = posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/'));
      // 严格检查是否属于该路径分支
      return nodePath == normalizedRoot || posix.isWithin(normalizedRoot, nodePath);
    }).map((node) => node.keyId).toList();

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
      debugPrint('[FileScannerStorage] 成功清理了 ${keysToDelete.length} 个属于 $normalizedRoot 的节点缓存。');
    }
  }

  /// 危险操作：清空整个扫描器数据库 (慎用)
  Future<void> clearAll() async {
    await _box.clear();
    debugPrint('[FileScannerStorage] 已清空全部缓存数据。');
  }
}