import 'package:uuid/uuid.dart';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/core/model/file_node.dart'; // 确保这里包含了 NodeStatus 的定义

class IncrementalTreeBuilder {
  final List<FileNode> roots = [];

  final _uuid = const Uuid();

  // 缓存文件夹节点，避免重复创建，实现 O(1) 查找
  final Map<String, FileNode> _dirCache = {};

  // 标记哪些父节点需要重新排序 (仅用于 UI 排序逻辑)
  final Set<Object> _dirtyNodes = {};

  // 记录本次构建中所有产生变更/新增的节点（包含文件和文件夹），用于持久化到 Hive
  final List<FileNode> _touchedNodes = [];

  String _lowerRootPath = "";
  String _originalRootPath = "";

  // 预编译正则，提高扫描性能。匹配 RJ 或 RJ0 开头，后接 6-8 位数字
  static final RegExp _rjRegex = RegExp(r'RJ0?\d{6,8}', caseSensitive: false);

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
    clear(keepRootPath: true);
    mergeChunk(allNodes);
  }

  /// 批量合并节点
  void mergeChunk(List<FileNode> flatNodes) {
    _dirtyNodes.clear();
    _touchedNodes.clear(); // 每次 chunk 处理前清空脏数据收集器

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
      // 如果需要，这里也可以为媒体文件本身做额外的初始状态处理
    );

    // 将进入树结构的文件记录到待保存列表
    _touchedNodes.add(fileNode);

    final parentPath = _getParentPath(fullPath);
    final lowerParentPath = parentPath.toLowerCase();

    // 场景 A: 直接位于根目录下
    if (lowerParentPath == _lowerRootPath) {
      _addOrReplaceNode(roots, fileNode);
      _dirtyNodes.add('ROOT');
      return;
    }

    // 场景 B: 位于子文件夹中
    final parentNode = _getOrCreateDirNode(parentPath);

    parentNode.children ??= [];
    _addOrReplaceNode(parentNode.children!, fileNode);
    _dirtyNodes.add(parentNode);
  }

  void _addOrReplaceNode(List<FileNode> list, FileNode newNode) {
    final index = list.indexWhere((n) => n.mediaStreamUrl == newNode.mediaStreamUrl);
    if (index != -1) {
      list[index] = newNode;
    } else {
      list.add(newNode);
    }
  }

  FileNode _getOrCreateDirNode(String dirPath) {
    final lowerDirPath = dirPath.toLowerCase();

    if (_dirCache.containsKey(lowerDirPath)) {
      return _dirCache[lowerDirPath]!;
    }

    final dirName = dirPath.split('/').last;

    // 动态分析该文件夹是否为 RJ 作品根目录
    final analysisResult = _analyzeFolderStatus(dirPath, dirName);

    final newDirNode = FileNode(
      type: NodeType.folder,
      title: dirName,
      children: [],
      hash: _uuid.v4(),
      mediaStreamUrl: dirPath,
      mediaDownloadUrl: null,
      nodeStatus: analysisResult.status, // 注入解析状态
      rjCode: analysisResult.rjCode,     // 注入 RJ 码
    );

    _dirCache[lowerDirPath] = newDirNode;

    // 关键：将隐式创建的文件夹节点也加入脏数据集合，以便后续存入 Hive
    _touchedNodes.add(newDirNode);

    final parentPath = _getParentPath(dirPath);
    final lowerParentPath = parentPath.toLowerCase();

    if (lowerParentPath == _lowerRootPath) {
      _addOrReplaceNode(roots, newDirNode);
      _dirtyNodes.add('ROOT');
    } else if (parentPath.length < _originalRootPath.length) {
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

  /// 核心判定逻辑：自顶向下首次匹配
  ({NodeStatus status, String? rjCode}) _analyzeFolderStatus(String fullPath, String currentDirName) {
    final segments = fullPath.split('/');

    for (final segment in segments) {
      final match = _rjRegex.firstMatch(segment);
      if (match != null) {
        // 找到了包含 RJ 码的层级
        if (segment == currentDirName) {
          // 如果命中层级正好是当前正在创建的文件夹，认定为待解析的作品根目录
          return (
          status: NodeStatus.pending,
          rjCode: match.group(0)!.toUpperCase() // 统一转为大写存入
          );
        } else {
          // 如果祖先节点已经包含了 RJ 码，说明当前文件夹是其子目录，降级为普通文件
          return (status: NodeStatus.normal, rjCode: null);
        }
      }
    }

    // 未发现任何 RJ 码特征
    return (status: NodeStatus.normal, rjCode: null);
  }

  void _sortNodes(List<FileNode> nodes) {
    nodes.sort((a, b) {
      final isAFolder = a.type == NodeType.folder;
      final isBFolder = b.type == NodeType.folder;

      if (isAFolder && !isBFolder) return -1;
      if (!isAFolder && isBFolder) return 1;

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  void clear({bool keepRootPath = false}) {
    roots.clear();
    _dirCache.clear();
    _dirtyNodes.clear();
    _touchedNodes.clear();
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

  /// 提取并清空本次生成的脏节点集合
  /// 扫描服务应当在 mergeChunk 执行完毕后，立刻调用此方法将其返回值写入 Hive
  List<FileNode> consumeTouchedNodes() {
    final nodesToSave = List<FileNode>.from(_touchedNodes);
    _touchedNodes.clear();
    return nodesToSave;
  }
}