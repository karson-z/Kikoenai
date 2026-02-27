import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';

import '../../storage/hive_storage.dart';


class FileScannerStorage {
  /// 单例模式
  static final FileScannerStorage _instance = FileScannerStorage._internal();
  FileScannerStorage._internal();
  factory FileScannerStorage() => _instance;

  /// 获取 Hive Box 引用
  Box<FileNode> get _box => AppStorage.scannerBox;

  /// 根据根路径获取缓存的所有文件节点
  /// 用于：页面进入时，立即加载缓存显示给用户 (Cache-First)
  List<FileNode> getNodesByRootPath(String rootPath) {
    if (_box.isEmpty) return [];

    // Hive 的 values 是一个 Iterable，对于 10万级以下的数据量，
    // 在内存中进行 where 过滤是非常快的。
    // 注意：确保 rootPath 格式标准化 (例如统一用 / 分隔)
    return _box.values.where((node) {
      // 1. 必须有路径
      if (node.mediaStreamUrl == null) return false;
      // 2. 必须属于当前扫描的根目录 (前缀匹配)
      return node.mediaStreamUrl!.startsWith(rootPath);
    }).toList();
  }

  /// 根据 Key 获取单个节点
  /// 用于：增量扫描时，对比新旧节点的修改时间 (lastModified)
  FileNode? getNode(String key) {
    return _box.get(key);
  }

  /// 获取所有数据
  List<FileNode> getAll() {
    return _box.values.toList();
  }
  /// 批量保存或更新节点
  /// 用于：Worker 扫描并发现新文件或文件变更后，批量写入 Hive
  Future<void> saveNodes(List<FileNode> nodes) async {
    if (nodes.isEmpty) return;
    // 将 List 转换为 Map<Key, Value> 以便使用 putAll
    // 使用 putAll 比循环调用 put 性能高得多
    final Map<String, FileNode> map = {};
    for (var node in nodes) {
      // 确保使用定义的 keyId (通常是 mediaStreamUrl)
      if (node.keyId.isNotEmpty) {
        map[node.keyId] = node;
      }
    }
    await _box.putAll(map);
    debugPrint('[FileScannerStorage] Saved/Updated ${nodes.length} nodes.');
  }

  /// 保存单个节点
  Future<void> saveNode(FileNode node) async {
    if (node.keyId.isNotEmpty) {
      await _box.put(node.keyId, node);
    }
  }
  /// 批量删除节点
  /// 用于：Worker 扫描结束后，发现某些文件在磁盘上已不存在，从缓存中移除
  Future<void> deleteNodes(List<String> keys) async {
    if (keys.isEmpty) return;
    await _box.deleteAll(keys);
    debugPrint('[FileScannerStorage] Deleted ${keys.length} nodes.');
  }
  /// 清空指定根路径下的所有缓存
  /// 用于：用户取消关联某个文件夹时
  Future<void> clearByRootPath(String rootPath) async {
    final keysToDelete = _box.values
        .where((node) => node.mediaStreamUrl != null && node.mediaStreamUrl!.startsWith(rootPath))
        .map((node) => node.keyId)
        .toList();

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }

  /// 清空整个 Box (慎用)
  Future<void> clearAll() async {
    await _box.clear();
  }
}