// import 'package:uuid/uuid.dart';
// import 'package:kikoenai/core/enums/node_type.dart';
// import 'package:kikoenai/core/model/file_node.dart';
//
// import '../../utils/scraper/scraper_storage.dart'; // 确保这里包含了 NodeStatus 的定义
//
// class IncrementalTreeBuilder {
//   final List<FileNode> roots = [];
//
//   final _uuid = const Uuid();
//
//   // 缓存文件夹节点，避免重复创建，实现 O(1) 查找
//   final Map<String, FileNode> _dirCache = {};
//
//   // 标记哪些父节点需要重新排序 (仅用于 UI 排序逻辑)
//   final Set<Object> _dirtyNodes = {};
//
//   // 记录本次构建中所有产生变更/新增的节点（包含文件和文件夹），用于持久化到 Hive
//   final List<FileNode> _touchedNodes = [];
//
//   String _lowerRootPath = "";
//   String _originalRootPath = "";
//
//   // 预编译正则，提高扫描性能。匹配 RJ 或 RJ0 开头，后接 6-8 位数字
//   static final RegExp _rjRegex = RegExp(r'RJ0?\d{6,8}', caseSensitive: false);
//
//   /// 设置根路径
//   void setRootPath(String path) {
//     if (path.isEmpty) return;
//     String normalized = path.replaceAll('\\', '/');
//     if (normalized.length > 1 && normalized.endsWith('/')) {
//       normalized = normalized.substring(0, normalized.length - 1);
//     }
//     _originalRootPath = normalized;
//     _lowerRootPath = normalized.toLowerCase();
//   }
//
//   /// 用于处理文件删除或全量刷新场景
//   void rebuild(List<FileNode> allNodes) {
//     clear(keepRootPath: true);
//     mergeChunk(allNodes);
//   }
//
//   /// 批量合并节点
//   void mergeChunk(List<FileNode> flatNodes) {
//     _dirtyNodes.clear();
//     _touchedNodes.clear(); // 每次 chunk 处理前清空脏数据收集器
//
//     for (final node in flatNodes) {
//       _insertNode(node);
//     }
//
//     // 1. 排序根节点
//     if (_dirtyNodes.contains('ROOT')) {
//       _sortNodes(roots);
//     }
//
//     // 2. 排序受影响的文件夹子节点
//     for (final dirNode in _dirtyNodes) {
//       if (dirNode is FileNode && dirNode.children != null) {
//         _sortNodes(dirNode.children!);
//       }
//     }
//   }
//
//   void _insertNode(FileNode originalNode) {
//     final rawPath = originalNode.mediaStreamUrl ?? "";
//     if (rawPath.isEmpty) return;
//
//     final fullPath = rawPath.replaceAll('\\', '/');
//     final lowerFullPath = fullPath.toLowerCase();
//
//     // 安全检查：必须属于当前根路径之下
//     if (!lowerFullPath.startsWith(_lowerRootPath)) return;
//
//     final fileNode = originalNode.copyWith(
//       hash: _uuid.v4(),
//       // 如果需要，这里也可以为媒体文件本身做额外的初始状态处理
//     );
//
//     // 将进入树结构的文件记录到待保存列表
//     _touchedNodes.add(fileNode);
//
//     final parentPath = _getParentPath(fullPath);
//     final lowerParentPath = parentPath.toLowerCase();
//
//     // 场景 A: 直接位于根目录下
//     if (lowerParentPath == _lowerRootPath) {
//       _addOrReplaceNode(roots, fileNode);
//       _dirtyNodes.add('ROOT');
//       return;
//     }
//
//     // 场景 B: 位于子文件夹中
//     final parentNode = _getOrCreateDirNode(parentPath);
//
//     parentNode.children ??= [];
//     _addOrReplaceNode(parentNode.children!, fileNode);
//     _dirtyNodes.add(parentNode);
//   }
//
//   void _addOrReplaceNode(List<FileNode> list, FileNode newNode) {
//     final index =
//         list.indexWhere((n) => n.mediaStreamUrl == newNode.mediaStreamUrl);
//     if (index != -1) {
//       list[index] = newNode;
//     } else {
//       list.add(newNode);
//     }
//   }
//
//   FileNode _getOrCreateDirNode(String dirPath) {
//     final lowerDirPath = dirPath.toLowerCase();
//
//     if (_dirCache.containsKey(lowerDirPath)) {
//       return _dirCache[lowerDirPath]!;
//     }
//
//     final dirName = dirPath.split('/').last;
//
//     // 动态分析该文件夹是否为 RJ 作品根目录
//     final analysisResult = _analyzeFolderStatus(dirPath, dirName);
//
//     final newDirNode = FileNode(
//       type: NodeType.folder,
//       title: dirName,
//       children: [],
//       hash: _uuid.v4(),
//       mediaStreamUrl: dirPath,
//       mediaDownloadUrl: null,
//       nodeStatus: analysisResult.status,
//       // 注入解析状态
//       rjCode: analysisResult.rjCode,
//     );
//
//     _dirCache[lowerDirPath] = newDirNode;
//
//     // 关键：将隐式创建的文件夹节点也加入脏数据集合，以便后续存入 Hive
//     _touchedNodes.add(newDirNode);
//
//     final parentPath = _getParentPath(dirPath);
//     final lowerParentPath = parentPath.toLowerCase();
//
//     if (lowerParentPath == _lowerRootPath) {
//       _addOrReplaceNode(roots, newDirNode);
//       _dirtyNodes.add('ROOT');
//     } else if (parentPath.length < _originalRootPath.length) {
//       _addOrReplaceNode(roots, newDirNode);
//       _dirtyNodes.add('ROOT');
//     } else {
//       final grandParent = _getOrCreateDirNode(parentPath);
//       grandParent.children ??= [];
//       _addOrReplaceNode(grandParent.children!, newDirNode);
//       _dirtyNodes.add(grandParent);
//     }
//
//     return newDirNode;
//   }
//
//   /// 核心判定逻辑：自顶向下首次匹配
//   ({NodeStatus status, String? rjCode}) _analyzeFolderStatus(
//       String fullPath, String currentDirName) {
//     final segments = fullPath.split('/');
//
//     for (final segment in segments) {
//       final match = _rjRegex.firstMatch(segment);
//       if (match != null) {
//         // 找到了包含 RJ 码的层级
//         if (segment == currentDirName) {
//           final rjCode = match.group(0)!.toUpperCase();
//           final isAlreadyParsed = ScraperStorage().hasWork(rjCode);
//           return (
//             status: isAlreadyParsed ? NodeStatus.parsed : NodeStatus.pending,
//             rjCode: rjCode
//           );
//         } else {
//           return (status: NodeStatus.normal, rjCode: null);
//         }
//       }
//     }
//
//     // 未发现任何 RJ 码特征
//     return (status: NodeStatus.normal, rjCode: null);
//   }
//
//   void _sortNodes(List<FileNode> nodes) {
//     nodes.sort((a, b) {
//       final isAFolder = a.type == NodeType.folder;
//       final isBFolder = b.type == NodeType.folder;
//
//       if (isAFolder && !isBFolder) return -1;
//       if (!isAFolder && isBFolder) return 1;
//
//       return a.title.toLowerCase().compareTo(b.title.toLowerCase());
//     });
//   }
//
//   void clear({bool keepRootPath = false}) {
//     roots.clear();
//     _dirCache.clear();
//     _dirtyNodes.clear();
//     _touchedNodes.clear();
//     if (!keepRootPath) {
//       _lowerRootPath = "";
//       _originalRootPath = "";
//     }
//   }
//
//   String _getParentPath(String path) {
//     final lastSeparator = path.lastIndexOf('/');
//     if (lastSeparator <= 0) return "";
//     return path.substring(0, lastSeparator);
//   }
//
//   /// 提取并清空本次生成的脏节点集合
//   /// 扫描服务应当在 mergeChunk 执行完毕后，立刻调用此方法将其返回值写入 Hive
//   List<FileNode> consumeTouchedNodes() {
//     final nodesToSave = List<FileNode>.from(_touchedNodes);
//     _touchedNodes.clear();
//     return nodesToSave;
//   }
// }
import 'package:uuid/uuid.dart';
import 'package:kikoenai/core/model/file_node.dart';

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

    // 继承数据库中原有的 hash，如果是新发现的则生成新的 hash
    FileNode fileNode = originalNode.copyWith(
      hash: originalNode.hash?.isNotEmpty == true ? originalNode.hash : _uuid.v4(),
    );

    // 【核心合并逻辑】：处理 Worker 显式发来的文件夹节点
    if (fileNode.isFolder) {
      if (_dirCache.containsKey(lowerFullPath)) {
        // 如果 Builder 之前已经被迫隐式创建过这个文件夹的占位符
        // 这里必须继承占位符里已经收集好的 children，防止子文件丢失
        fileNode = fileNode.copyWith(children: _dirCache[lowerFullPath]!.children);
      } else {
        fileNode = fileNode.copyWith(children: []);
      }
      // 更新缓存为这个携带有真实 RJ 码和状态的完整节点
      _dirCache[lowerFullPath] = fileNode;
    }

    // 将进入树结构的文件记录到待保存列表
    _touchedNodes.add(fileNode);

    final parentPath = _getParentPath(fullPath);
    final lowerParentPath = parentPath.toLowerCase();

    // 场景 A: 直接位于根目录下
    if (lowerParentPath == _lowerRootPath || parentPath.length < _originalRootPath.length) {
      _addOrReplaceNode(roots, fileNode);
      _dirtyNodes.add('ROOT');
      return;
    }

    // 场景 B: 位于子文件夹中
    final parentNode = _getOrCreateDirNode(parentPath);
    _addOrReplaceNode(parentNode.children!, fileNode);
    _dirtyNodes.add(parentNode);
  }

  void _addOrReplaceNode(List<FileNode> list, FileNode newNode) {
    final index = list.indexWhere((n) => n.mediaStreamUrl == newNode.mediaStreamUrl);
    if (index != -1) {
      // 替换时保留原有的 children (非常重要！)
      list[index] = newNode.copyWith(children: list[index].children);
    } else {
      list.add(newNode);
    }
  }

  /// 隐式文件夹创建器：这里现在变成了一个极其纯粹的兜底方法
  FileNode _getOrCreateDirNode(String dirPath) {
    final lowerDirPath = dirPath.toLowerCase();

    if (_dirCache.containsKey(lowerDirPath)) {
      return _dirCache[lowerDirPath]!;
    }

    final dirName = dirPath.split('/').last;

    // 当遇到 Worker 尚未传过来的父级目录时，生成一个纯净的空白文件夹
    // 稍后 Worker 扫描到这个真实的目录时，会通过 _insertNode 将它完美覆盖升级
    final newDirNode = FileNode(
      type: NodeType.folder,
      title: dirName,
      children: [],
      hash: _uuid.v4(),
      mediaStreamUrl: dirPath,
      mediaDownloadUrl: null,
      nodeStatus: NodeStatus.normal, // 默认普普通通
      rjCode: null,                  // 没有 RJ 码
    );

    _dirCache[lowerDirPath] = newDirNode;
    _touchedNodes.add(newDirNode);

    final parentPath = _getParentPath(dirPath);
    final lowerParentPath = parentPath.toLowerCase();

    if (lowerParentPath == _lowerRootPath || parentPath.length < _originalRootPath.length) {
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
  List<FileNode> consumeTouchedNodes() {
    final nodesToSave = List<FileNode>.from(_touchedNodes);
    _touchedNodes.clear();
    return nodesToSave;
  }
}