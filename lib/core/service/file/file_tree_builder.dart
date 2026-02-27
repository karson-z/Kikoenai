import 'package:uuid/uuid.dart';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';

class IncrementalTreeBuilder {
  final List<FileNode> roots = [];

  final _uuid = const Uuid();

  // 缓存文件夹节点，避免重复创建，实现 O(1) 查找
  final Map<String, FileNode> _dirCache = {};

  // 标记哪些节点变脏了
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

  /// 用于处理文件删除或全量刷新场景
  void rebuild(List<FileNode> allNodes) {
    // 保留 RootPath，只清空数据
    clear(keepRootPath: true);
    mergeChunk(allNodes);
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

    // 安全检查：必须属于当前根路径之下
    if (!lowerFullPath.startsWith(_lowerRootPath)) return;

    final fileNode = originalNode.copyWith(
      hash: _uuid.v4(),
    );

    final parentPath = _getParentPath(fullPath);
    final lowerParentPath = parentPath.toLowerCase();

    // 场景 A: 直接位于根目录下
    if (lowerParentPath == _lowerRootPath) {
      _addOrReplaceNode(roots, fileNode);
      _dirtyNodes.add('ROOT');
      return;
    }

    // 场景 B: 位于子文件夹中
    // 获取或创建父文件夹节点
    final parentNode = _getOrCreateDirNode(parentPath);

    // 挂载到父节点
    parentNode.children ??= [];
    _addOrReplaceNode(parentNode.children!, fileNode);
    _dirtyNodes.add(parentNode);
  }

  /// 插入或替换逻辑
  /// 如果列表中已存在同路径的节点（更新场景），先移除旧的，再添加新的
  void _addOrReplaceNode(List<FileNode> list, FileNode newNode) {
    // 查找是否存在同名（同路径）节点
    // 注意：这里用 mediaStreamUrl (路径) 作为唯一标识
    final index = list.indexWhere((n) => n.mediaStreamUrl == newNode.mediaStreamUrl);

    if (index != -1) {
      // 替换旧节点 (Update)
      list[index] = newNode;
    } else {
      // 追加新节点 (Insert)
      list.add(newNode);
    }
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
      hash: _uuid.v4(), // 文件夹也生成一个 UI ID
      mediaStreamUrl: dirPath, // 文件夹路径暂存在这里，用于逻辑判断
      mediaDownloadUrl: null,
    );

    _dirCache[lowerDirPath] = newDirNode;

    // 递归向上找
    final parentPath = _getParentPath(dirPath);
    final lowerParentPath = parentPath.toLowerCase();

    if (lowerParentPath == _lowerRootPath) {
      _addOrReplaceNode(roots, newDirNode);
      _dirtyNodes.add('ROOT');
    } else if (parentPath.length < _originalRootPath.length) {
      // 路径异常保护：防止死循环或越界
      _addOrReplaceNode(roots, newDirNode);
      _dirtyNodes.add('ROOT');
    } else {
      final grandParent = _getOrCreateDirNode(parentPath);
      grandParent.children ??= [];
      _addOrReplaceNode(grandParent.children!, newDirNode);
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

  /// [修改] 清空方法，支持保留 RootPath
  void clear({bool keepRootPath = false}) {
    roots.clear();
    _dirCache.clear();
    _dirtyNodes.clear();
    if (!keepRootPath) {
      _lowerRootPath = "";
      _originalRootPath = "";
    }
  }

  String _getParentPath(String path) {
    final lastSeparator = path.lastIndexOf('/');
    if (lastSeparator <= 0) return "";
    return path.substring(0, lastSeparator);
  }
}