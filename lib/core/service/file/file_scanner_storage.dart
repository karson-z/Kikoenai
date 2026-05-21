import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:path/path.dart' as p;
import '../../storage/hive_storage.dart';
import 'file_scanner_service.dart';

class FileScannerStorage {
  FileScannerStorage._();
  static final FileScannerStorage _instance = FileScannerStorage._();
  factory FileScannerStorage() => _instance;

  Box<FileNode> get _box => AppStorage.scannerBox;

  String _computeMd5(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return md5.convert(utf8.encode(normalized)).toString();
  }

  String _generateIsolatedKey(ScanMode mode, String originalPath) {
    final pathMd5 = _computeMd5(originalPath);
    return '${mode.name}_$pathMd5';
  }

  bool _isModeKey(ScanMode mode, dynamic key) {
    return key is String && key.startsWith('${mode.name}_');
  }

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

  FileNode? getNode(ScanMode mode, String path) {
    return _box.get(_generateIsolatedKey(mode, path));
  }

  List<FileNode> getAllByMode(ScanMode mode) {
    return _box.toMap().entries
        .where((e) => _isModeKey(mode, e.key))
        .map((e) => e.value)
        .toList();
  }

  Future<void> saveNodes(ScanMode mode, List<FileNode> nodes) async {
    if (nodes.isEmpty) return;

    final Map<String, FileNode> map = {};
    for (var node in nodes) {
      if (node.keyId.isNotEmpty) {
        final pathMd5 = _computeMd5(node.keyId);
        final nodeWithHash = node.copyWith(hash: pathMd5);
        map['${mode.name}_$pathMd5'] = nodeWithHash;
      }
    }
    await _box.putAll(map);
    debugPrint('[FileScannerStorage] (${mode.name}) 成功保存了 ${nodes.length} 个扁平节点。');
  }

  Future<void> saveNode(ScanMode mode, FileNode node) async {
    if (node.keyId.isNotEmpty) {
      final pathMd5 = _computeMd5(node.keyId);
      final nodeWithHash = node.copyWith(hash: pathMd5);
      await _box.put('${mode.name}_$pathMd5', nodeWithHash);
    }
  }

  Future<void> deleteNodes(ScanMode mode, List<String> paths) async {
    if (paths.isEmpty) return;
    final keysToDelete = paths.map((p) => _generateIsolatedKey(mode, p)).toList();
    await _box.deleteAll(keysToDelete);
    debugPrint('[FileScannerStorage] (${mode.name}) 成功删除了 ${keysToDelete.length} 个失效缓存节点。');
  }

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
      debugPrint('[FileScannerStorage] (${mode.name}) 成功清理了 ${keysToDelete.length} 个属于 $normalizedRoot 的缓存。');
    }
  }

  Future<void> clearByMode(ScanMode mode) async {
    final keysToDelete = _box.keys.where((k) => _isModeKey(mode, k)).toList();
    await _box.deleteAll(keysToDelete);
    debugPrint('[FileScannerStorage] (${mode.name}) 已清空该模式下的全部缓存数据。');
  }

  List<FileNode> getAllAcrossModes() {
    return _box.values.toList();
  }

  Future<void> clearAbsolutelyAll() async {
    await _box.clear();
    debugPrint('[FileScannerStorage] 已彻底清空所有模式的缓存数据。');
  }

  FileNode? getWorkFileTreeLocally(int workId) {
    final allNodes = getAllAcrossModes();
    final workFiles = allNodes.where((node) => node.workId == workId).toList();
    if (workFiles.isEmpty) return null;

    final posix = p.Context(style: p.Style.posix);
    String? commonRoot;

    for (var node in workFiles) {
      if (node.mediaStreamUrl == null) continue;
      final dir = posix.dirname(posix.normalize(node.mediaStreamUrl!.replaceAll('\\', '/')));
      if (commonRoot == null) {
        commonRoot = dir;
      } else {
        while (!dir.toLowerCase().startsWith(commonRoot!.toLowerCase()) && commonRoot != '/') {
          commonRoot = posix.dirname(commonRoot);
        }
      }
    }

    if (commonRoot == null) return null;

    final treeRoots = _buildTreeInternal(workFiles, commonRoot);

    return FileNode(
      type: NodeType.folder,
      title: posix.basename(commonRoot),
      mediaStreamUrl: commonRoot,
      source: NodeSource.localWork,
      workId: workId,
      children: treeRoots,
    );
  }

  FileNode? getFolderFiles(ScanMode mode, String folderPath) {
    final posix = p.Context(style: p.Style.posix);
    final normalizedFolder = posix.normalize(folderPath.replaceAll('\\', '/'));

    final cachedNodes = getNodesByRootPath(mode, normalizedFolder);
    if (cachedNodes.isEmpty) return null;

    final treeRoots = _buildTreeInternal(cachedNodes, normalizedFolder);

    return FileNode(
      type: NodeType.folder,
      title: posix.basename(normalizedFolder),
      mediaStreamUrl: normalizedFolder,
      source: NodeSource.localWork,
      children: treeRoots,
    );
  }

  Future<void> updateNodeStatusByKeyGlobally(String path, NodeStatus newStatus) async {
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
      debugPrint('[FileScannerStorage] (全局) 已同步更新路径节点的状态为 ${newStatus.name}');
    }
  }

  /// 纯函数路径逆推树算法（解决不可变对象无 Setter 的编译限制）
  List<FileNode> _buildTreeInternal(List<FileNode> flatNodes, String rootPath) {
    final posix = p.Context(style: p.Style.posix);
    final String normalizedRoot = posix.normalize(rootPath.replaceAll('\\', '/'));
    final String lowerRoot = normalizedRoot.toLowerCase();

    final Map<String, List<FileNode>> fileMap = {};
    final Map<String, String> dirLowerToOriginal = {};
    dirLowerToOriginal[lowerRoot] = normalizedRoot;

    for (final node in flatNodes) {
      final url = node.mediaStreamUrl;
      if (url == null || url.isEmpty) continue;

      final normalizedUrl = posix.normalize(url.replaceAll('\\', '/'));
      final dirPath = posix.dirname(normalizedUrl);

      fileMap.putIfAbsent(dirPath.toLowerCase(), () => []).add(node);

      String currentDir = dirPath;
      while (true) {
        final currentDirLower = currentDir.toLowerCase();
        dirLowerToOriginal[currentDirLower] = currentDir;

        if (currentDirLower == lowerRoot || currentDir == posix.dirname(currentDir)) {
          break;
        }
        currentDir = posix.dirname(currentDir);
      }
    }

    final Map<String, Set<String>> subDirMap = {};
    for (final dirLower in dirLowerToOriginal.keys) {
      if (dirLower == lowerRoot) continue;
      final originalDir = dirLowerToOriginal[dirLower]!;
      final parentLower = posix.dirname(originalDir).toLowerCase();
      subDirMap.putIfAbsent(parentLower, () => {}).add(dirLower);
    }

    List<FileNode> buildChildren(String currentPath) {
      final List<FileNode> children = [];
      final currentPathLower = currentPath.toLowerCase();

      final files = fileMap[currentPathLower] ?? [];
      children.addAll(files);

      final subDirsLower = subDirMap[currentPathLower] ?? {};
      for (final subDirLower in subDirsLower) {
        final originalSubDir = dirLowerToOriginal[subDirLower]!;
        final subChildren = buildChildren(originalSubDir);

        children.add(FileNode(
          type: NodeType.folder,
          title: posix.basename(originalSubDir),
          mediaStreamUrl: originalSubDir,
          source: NodeSource.localWork,
          children: subChildren,
        ));
      }

      children.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      return children;
    }

    return buildChildren(normalizedRoot);
  }
}