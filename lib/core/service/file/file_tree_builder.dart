import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // 需引入 uuid 包
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';

class IncrementalTreeBuilder {
  final List<FileNode> roots = [];

  final _uuid = const Uuid();

  final Map<String, FileNode> _dirCache = {};

  final Set<Object> _dirtyNodes = {};

  String _lowerRootPath = "";
  String _originalRootPath = "";

  /// 设置根路径
  void setRootPath(String path) {
    if (path.isEmpty) return;
    String normalized = path.replaceAll('\\', '/');
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    _originalRootPath = normalized;
    _lowerRootPath = normalized.toLowerCase();
  }

  /// 批量合并节点
  void mergeChunk(List<FileNode> flatNodes) {
    _dirtyNodes.clear();

    for (final node in flatNodes) {
      _insertNode(node);
    }

    // 1. 排序根节点
    if (_dirtyNodes.contains('ROOT')) {
      _sortNodes(roots);
    }

    // 2. 排序受影响的文件夹子节点
    for (final dirNode in _dirtyNodes) {
      if (dirNode is FileNode && dirNode.children != null) {
        _sortNodes(dirNode.children!);
      }
    }
  }

  void _insertNode(FileNode originalNode) {
    final rawPath = originalNode.mediaStreamUrl ?? "";
    if (rawPath.isEmpty) return;

    final fullPath = rawPath.replaceAll('\\', '/');
    final lowerFullPath = fullPath.toLowerCase();

    // 安全检查：必须以根路径开头
    if (!lowerFullPath.startsWith(_lowerRootPath)) return;
    final fileNode = originalNode.copyWith(
      hash: _uuid.v4(),
    );

    final parentPath = _getParentPath(fullPath);
    final lowerParentPath = parentPath.toLowerCase();

    // 判断是否直接位于根目录下
    if (lowerParentPath == _lowerRootPath) {
      roots.add(fileNode);
      _dirtyNodes.add('ROOT');
      return;
    }

    // 获取或创建父文件夹节点
    final parentNode = _getOrCreateDirNode(parentPath);

    // 挂载
    parentNode.children?.add(fileNode);
    _dirtyNodes.add(parentNode);
  }

  FileNode _getOrCreateDirNode(String dirPath) {
    final lowerDirPath = dirPath.toLowerCase();

    if (_dirCache.containsKey(lowerDirPath)) {
      return _dirCache[lowerDirPath]!;
    }

    final dirName = dirPath.split('/').last;

    final newDirNode = FileNode(
      type: NodeType.folder,
      title: dirName,
      children: [], // 初始化可变列表
      hash: null,   // 文件夹无 ID
      mediaStreamUrl: dirPath, // 文件夹路径暂存在这里，用于逻辑判断
      mediaDownloadUrl: null,
    );

    _dirCache[lowerDirPath] = newDirNode;

    // 递归向上找
    final parentPath = _getParentPath(dirPath);
    final lowerParentPath = parentPath.toLowerCase();

    if (lowerParentPath == _lowerRootPath) {
      roots.add(newDirNode);
      _dirtyNodes.add('ROOT');
    } else if (parentPath.length < _originalRootPath.length) {
      // 路径异常保护
      roots.add(newDirNode);
      _dirtyNodes.add('ROOT');
    } else {
      final grandParent = _getOrCreateDirNode(parentPath);
      grandParent.children?.add(newDirNode);
      _dirtyNodes.add(grandParent);
    }

    return newDirNode;
  }

  void _sortNodes(List<FileNode> nodes) {
    nodes.sort((a, b) {
      // 1. 类型优先级：文件夹(-1) < 文件(1)
      final isAFolder = a.type == NodeType.folder;
      final isBFolder = b.type == NodeType.folder;

      if (isAFolder && !isBFolder) return -1;
      if (!isAFolder && isBFolder) return 1;

      // 2. 同类型按名称排序
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  void clear() {
    roots.clear();
    _dirCache.clear();
    _dirtyNodes.clear();
    _lowerRootPath = "";
    _originalRootPath = "";
  }

  String _getParentPath(String path) {
    final lastSeparator = path.lastIndexOf('/');
    if (lastSeparator <= 0) return "";
    return path.substring(0, lastSeparator);
  }
}