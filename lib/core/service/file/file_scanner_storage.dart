import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';

import '../../storage/hive_storage.dart';
import 'file_node_library_index.dart';
import 'scan_mode.dart';

class FileScannerStorage {
  FileScannerStorage._();
  static final FileScannerStorage _instance = FileScannerStorage._();
  factory FileScannerStorage() => _instance;

  Box<FileNode> get _box => AppStorage.scannerBox;

  String _computeMd5(String value) {
    final normalized = FileNodeLibraryIndex.normalizePath(value).toLowerCase();
    return md5.convert(utf8.encode(normalized)).toString();
  }

  String _keyFor(ScanMode mode, String nodeKey) {
    return '${mode.name}_${_computeMd5(nodeKey)}';
  }

  bool _isModeKey(ScanMode mode, dynamic key) {
    return key is String && key.startsWith('${mode.name}_');
  }

  List<FileNode> getNodesByRootPath(ScanMode mode, String rootPath) {
    final normalizedRoot = FileNodeLibraryIndex.normalizePath(
      rootPath,
    ).toLowerCase();

    return _box
        .toMap()
        .entries
        .where((entry) => _isModeKey(mode, entry.key))
        .map((entry) => entry.value)
        .where((node) {
          final nodeRoot = node.rootPath;
          if (nodeRoot != null && nodeRoot.isNotEmpty) {
            return FileNodeLibraryIndex.normalizePath(nodeRoot).toLowerCase() ==
                normalizedRoot;
          }

          final nodePath = node.path ?? node.mediaStreamUrl;
          if (nodePath == null || nodePath.isEmpty) return false;

          final normalizedNode = FileNodeLibraryIndex.normalizePath(
            nodePath,
          ).toLowerCase();
          return normalizedNode == normalizedRoot ||
              normalizedNode.startsWith('$normalizedRoot/');
        })
        .toList();
  }

  FileNode? getNode(ScanMode mode, String nodeKey) {
    return _box.get(_keyFor(mode, nodeKey));
  }

  List<FileNode> getAllByMode(ScanMode mode) {
    return _box
        .toMap()
        .entries
        .where((entry) => _isModeKey(mode, entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  List<FileNode> getAllAcrossModes() {
    return _box.values.toList();
  }

  Future<void> saveNodes(ScanMode mode, List<FileNode> nodes) async {
    if (nodes.isEmpty) return;

    final map = <String, FileNode>{};
    for (final node in nodes) {
      final key = node.keyId;
      if (key.isEmpty) continue;
      map[_keyFor(mode, key)] = node;
    }

    await _box.putAll(map);
    debugPrint(
      '[FileScannerStorage] (${mode.name}) saved ${map.length} flat nodes.',
    );
  }

  Future<void> deleteNodes(ScanMode mode, List<String> nodeKeys) async {
    if (nodeKeys.isEmpty) return;
    await _box.deleteAll(nodeKeys.map((key) => _keyFor(mode, key)));
    debugPrint(
      '[FileScannerStorage] (${mode.name}) deleted ${nodeKeys.length} stale nodes.',
    );
  }

  Future<void> clearByRootPath(ScanMode mode, String rootPath) async {
    final normalizedRoot = FileNodeLibraryIndex.normalizePath(
      rootPath,
    ).toLowerCase();

    final keys = _box
        .toMap()
        .entries
        .where((entry) {
          if (!_isModeKey(mode, entry.key)) return false;
          final node = entry.value;

          final nodeRoot = node.rootPath;
          if (nodeRoot != null && nodeRoot.isNotEmpty) {
            return FileNodeLibraryIndex.normalizePath(nodeRoot).toLowerCase() ==
                normalizedRoot;
          }

          final nodePath = node.path ?? node.mediaStreamUrl;
          if (nodePath == null || nodePath.isEmpty) return false;
          final normalizedNode = FileNodeLibraryIndex.normalizePath(
            nodePath,
          ).toLowerCase();
          return normalizedNode == normalizedRoot ||
              normalizedNode.startsWith('$normalizedRoot/');
        })
        .map((entry) => entry.key)
        .toList();

    await _box.deleteAll(keys);
    debugPrint(
      '[FileScannerStorage] (${mode.name}) cleared ${keys.length} nodes under $rootPath.',
    );
  }

  Future<void> clearByMode(ScanMode mode) async {
    final keys = _box.keys.where((key) => _isModeKey(mode, key)).toList();
    await _box.deleteAll(keys);
    debugPrint(
      '[FileScannerStorage] (${mode.name}) cleared ${keys.length} nodes.',
    );
  }

  Future<void> clearAbsolutelyAll() async {
    await _box.clear();
    debugPrint('[FileScannerStorage] cleared all scanner nodes.');
  }

  FileNodeLibraryIndex? getWorkFileIndexLocally(int workId) {
    final workFiles = getAllAcrossModes()
        .where((node) => node.workId == workId && !node.isFolder)
        .toList();

    if (workFiles.isEmpty) return null;

    final commonRoot = _commonFolderRoot(workFiles);
    if (commonRoot == null) return null;

    return FileNodeLibraryIndex(
      flatNodes: workFiles,
      rootPath: commonRoot,
      fallbackFolderSource: NodeSource.localWork,
    );
  }

  FileNode? getWorkFileTreeLocally(int workId) {
    final index = getWorkFileIndexLocally(workId);
    if (index == null) return null;

    final root = FileNodeLibraryIndex.normalizePath(index.rootPath);
    return FileNode(
      type: NodeType.folder,
      title: NodeFolder(root).name,
      mediaStreamUrl: root,
      path: root,
      rootPath: root,
      source: NodeSource.localWork,
      workId: workId,
      children: index.toTreeChildren(),
    );
  }

  Future<void> updateNodeStatusByKeyGlobally(
    String nodeKey,
    NodeStatus newStatus,
  ) async {
    final updates = <String, FileNode>{};

    for (final mode in ScanMode.values) {
      final key = _keyFor(mode, nodeKey);
      final node = _box.get(key);
      if (node != null) updates[key] = node.copyWith(nodeStatus: newStatus);
    }

    if (updates.isNotEmpty) await _box.putAll(updates);
  }

  Future<void> updateNodeStatusByWorkIdGlobally(
    int workId,
    NodeStatus newStatus,
  ) async {
    final updates = <dynamic, FileNode>{};

    for (final entry in _box.toMap().entries) {
      final node = entry.value;
      if (node.workId != workId || node.nodeStatus == newStatus) continue;
      updates[entry.key] = node.copyWith(nodeStatus: newStatus);
    }

    if (updates.isNotEmpty) await _box.putAll(updates);
  }

  String? _commonFolderRoot(List<FileNode> nodes) {
    String? root;

    for (final node in nodes) {
      final folder =
          node.folderPath ??
          FileNodeLibraryIndex.dirName(node.path ?? node.mediaStreamUrl ?? '');
      if (folder.isEmpty) continue;

      if (root == null) {
        root = folder;
        continue;
      }

      while (root != null &&
          !folder.toLowerCase().startsWith(root.toLowerCase())) {
        final parent = FileNodeLibraryIndex.dirName(root);
        if (parent == root) return root;
        root = parent;
      }
    }

    return root;
  }
}
