import '../../model/file_node.dart';
import '../../../features/file_sort/domain/file_sort_option.dart';

class FileNodeLibraryIndex {
  final String rootPath;
  final NodeSource fallbackFolderSource;

  final Map<NodeFolder, List<FileNode>> folderMap = {};
  final Map<String, FileNode> nodeByKey = {};

  /// 当前排序配置，默认按 title 升序。
  FileSortOption _currentSort = FileSortOption.defaultOption;

  late FolderTreeNode rootNode;

  FolderTreeNode _currentNode = FolderTreeNode.root();
  NodeFolder? _currentFolder;

  FileNodeLibraryIndex({
    required List<FileNode> flatNodes,
    required this.rootPath,
    this.fallbackFolderSource = NodeSource.localWork,
  }) {
    _build(flatNodes);
  }

  factory FileNodeLibraryIndex.fromRemoteTree({
    required List<FileNode> roots,
    required int workId,
    NodeSource source = NodeSource.asmrServer,
  }) {
    final rootPath = remoteRootPath(workId);
    return FileNodeLibraryIndex(
      flatNodes: flattenRemoteTree(
        roots: roots,
        workId: workId,
        source: source,
      ),
      rootPath: rootPath,
      fallbackFolderSource: source,
    );
  }

  /// 从任意 FileNode 树（含 children 嵌套）构建索引。
  ///
  /// 与 [fromRemoteTree] 不同，本工厂不会覆盖节点原有的 `source` / `workId`，
  /// 适用于本地树、混合来源树等通用场景。
  /// [rootPath] 缺省时取首个含非空 `rootPath` 的节点，再缺省则使用 `tree://root`。
  factory FileNodeLibraryIndex.fromTree({
    required List<FileNode> roots,
    String? rootPath,
    NodeSource fallbackFolderSource = NodeSource.localWork,
  }) {
    final effectiveRoot =
        rootPath ??
        roots
            .map((n) => n.rootPath)
            .firstWhere((p) => p != null && p.isNotEmpty, orElse: () => null) ??
        'tree://root';

    final flatNodes = <FileNode>[];
    for (final node in roots) {
      _flattenTreeNode(
        node: node,
        parentPath: effectiveRoot,
        rootPath: effectiveRoot,
        flatNodes: flatNodes,
      );
    }

    return FileNodeLibraryIndex(
      flatNodes: flatNodes,
      rootPath: effectiveRoot,
      fallbackFolderSource: fallbackFolderSource,
    );
  }

  static String remoteRootPath(int workId) => 'asmr://$workId';

  static List<FileNode> flattenRemoteTree({
    required List<FileNode> roots,
    required int workId,
    NodeSource source = NodeSource.asmrServer,
  }) {
    final rootPath = remoteRootPath(workId);
    final flatNodes = <FileNode>[];

    for (final node in roots) {
      _flattenRemoteNode(
        node: node,
        parentPath: rootPath,
        rootPath: rootPath,
        workId: workId,
        source: source,
        flatNodes: flatNodes,
      );
    }

    return flatNodes;
  }

  NodeFolder? get currentFolder => _currentFolder;

  NodeFolder get rootFolder => NodeFolder(normalizePath(rootPath));

  bool get isHome => _currentFolder == null;

  List<NodeFolder> get currentFolders {
    return _currentNode.foldersList;
  }

  List<FileNode> get currentFiles {
    return folderMap[_currentFolder ?? rootFolder] ?? const [];
  }

  List<FileNode> get currentChildren {
    final folders = currentFolders.map(_folderToFileNode);
    return [...folders, ...currentFiles];
  }

  void stepIn(NodeFolder folder) {
    final next =
        _currentNode.children[folder] ??
        rootNode.lookup(folder, stopAtRootPath: rootPath);
    if (next == null) return;

    _currentNode = next;
    _currentFolder = folder;
  }

  void stepOut() {
    final parentNode = _currentNode.parentNode;
    if (parentNode == null || parentNode == rootNode) {
      _currentNode = rootNode;
      _currentFolder = null;
      return;
    }

    _currentNode = parentNode;
    _currentFolder = parentNode.folder;
  }

  void goHome() {
    _currentNode = rootNode;
    _currentFolder = null;
  }

  void jumpTo(String targetFolderPath) {
    final normalizedPath = normalizePath(targetFolderPath);
    final targetFolder = NodeFolder(normalizedPath);

    if (normalizedPath == normalizePath(rootPath)) {
      goHome();
      return;
    }

    final targetNode = rootNode.lookup(targetFolder, stopAtRootPath: rootPath);

    if (targetNode != null) {
      _currentNode = targetNode;
      _currentFolder = targetFolder;
    }
  }

  /// 当前从根目录（不含）到当前位置的文件夹链，作为面包屑路径。
  ///
  /// 处于根目录（home）时返回空列表。每项为对应层级的文件夹 [FileNode]。
  /// 顺序：从根目录下一级到当前所在目录。
  List<FileNode> get breadcrumbPath {
    if (_currentFolder == null) return const [];
    final result = <FileNode>[];
    var node = _currentNode;
    while (node.folder != null) {
      result.insert(0, _folderToFileNode(node.folder!));
      final parent = node.parentNode;
      if (parent == null || parent == rootNode) break;
      node = parent;
    }
    return result;
  }

  /// 按面包屑索引跳转。
  ///
  /// - `index < 0`：回到根目录（home）。
  /// - `0 <= index < breadcrumbPath.length`：跳转到第 `index` 级文件夹。
  /// - 超出范围则忽略。
  void jumpToBreadcrumbIndex(int index) {
    if (index < 0) {
      goHome();
      return;
    }
    final path = breadcrumbPath;
    if (index >= path.length) return;
    final targetPath = path[index].path ?? path[index].mediaStreamUrl ?? '';
    if (targetPath.isEmpty) return;
    jumpTo(targetPath);
  }

  List<FileNode> getFilesInFolder(NodeFolder folder, {bool recursive = false}) {
    if (!recursive) return folderMap[folder] ?? const [];

    final node = rootNode.lookup(folder, stopAtRootPath: rootPath);
    if (node == null) return folderMap[folder] ?? const [];

    final files = <FileNode>[...folderMap[folder] ?? const []];

    node.walk((child) {
      final folder = child.folder;
      if (folder != null) {
        files.addAll(folderMap[folder] ?? const []);
      }
    });

    return files;
  }

  /// 获取某个 folder 下的直接子项统计（不递归）。
  ({int folders, int files, int total}) directItemCount(NodeFolder folder) {
    final treeNode = rootNode.lookup(
      folder,
      stopAtRootPath: normalizePath(rootPath),
    );
    final folders = treeNode?.children.length ?? 0;
    final files = folderMap[folder]?.length ?? 0;
    return (folders: folders, files: files, total: folders + files);
  }

  /// 获取 folder 下的所有递归文件（含子文件夹中的文件）。
  List<FileNode> recursiveFilesOf(NodeFolder folder) {
    return getFilesInFolder(folder, recursive: true);
  }

  /// 递归遍历 folder 树，依次访问每个 folder 节点（含其本身）。
  ///
  /// [visit] 接收当前 folder 的 [NodeFolder] 与其在 [folderMap] 中的直接文件列表。
  void walkFolders(void Function(NodeFolder folder, List<FileNode> directFiles) visit) {
    void visitTree(FolderTreeNode treeNode) {
      final folder = treeNode.folder;
      if (folder != null) {
        visit(folder, folderMap[folder] ?? const []);
        for (final child in treeNode.children.values) {
          visitTree(child);
        }
      } else {
        // rootNode：仅遍历子级
        for (final child in treeNode.children.values) {
          visitTree(child);
        }
      }
    }

    visitTree(rootNode);
  }

  List<FileNode> toTreeChildren() {
    return _childrenFor(rootNode);
  }

  List<FileNode> _childrenFor(FolderTreeNode treeNode) {
    final folders = treeNode.foldersList.map((folder) {
      final child = treeNode.children[folder];
      return _folderToFileNode(
        folder,
      ).copyWith(children: child == null ? const [] : _childrenFor(child));
    });

    final files = folderMap[treeNode.folder ?? rootFolder] ?? const [];

    return [...folders, ...files];
  }

  void _build(List<FileNode> flatNodes) {
    final normalizedRoot = normalizePath(rootPath);
    rootNode = FolderTreeNode.root();
    _currentNode = rootNode;
    _currentFolder = null;

    for (final node in flatNodes) {
      if (node.isFolder) continue;

      final normalizedNode = _normalizeNode(node, normalizedRoot);
      final folder = normalizedNode.folder;
      if (folder == null) continue;

      nodeByKey[normalizedNode.keyId] = normalizedNode;
      folderMap.putIfAbsent(folder, () => []).add(normalizedNode);
    }

    for (final folder in folderMap.keys) {
      var current = rootNode;

      for (final part in folder.buildInbetweenFolders(
        stopAtRootPath: normalizedRoot,
      )) {
        current = current.children.putIfAbsent(
          part,
          () => FolderTreeNode(parentNode: current, folder: part),
        );
      }
    }

    _sort(_currentSort);
  }

  FileNode _normalizeNode(FileNode node, String normalizedRoot) {
    final rawPath = node.path ?? node.mediaStreamUrl ?? '';
    final normalizedPath = normalizePath(rawPath);
    final folderPath = node.folderPath ?? dirName(normalizedPath);

    return node.copyWith(
      path: normalizedPath,
      mediaStreamUrl: node.mediaStreamUrl ?? normalizedPath,
      mediaDownloadUrl: node.mediaDownloadUrl ?? normalizedPath,
      rootPath: node.rootPath ?? normalizedRoot,
      folderPath: normalizePath(folderPath),
      parentPath: node.parentPath ?? normalizePath(folderPath),
      depth: _depthFromRoot(normalizedRoot, normalizedPath),
    );
  }

  FileNode _folderToFileNode(NodeFolder folder) {
    final files = getFilesInFolder(folder, recursive: true);
    final sample = files.firstOrNull;
    final treeNode = rootNode.lookup(
      folder,
      stopAtRootPath: normalizePath(rootPath),
    );
    final directFoldersCount = treeNode?.children.length ?? 0;
    final directFilesCount = folderMap[folder]?.length ?? 0;

    return FileNode(
      type: NodeType.folder,
      title: folder.name,
      mediaStreamUrl: folder.normalized,
      path: folder.normalized,
      folderPath: folder.parent?.normalized,
      parentPath: folder.parent?.normalized,
      rootPath: normalizePath(rootPath),
      depth: _depthFromRoot(normalizePath(rootPath), folder.normalized),
      source: sample?.source ?? fallbackFolderSource,
      workId: sample?.workId,
      workTitle: sample?.workTitle,
      artist: sample?.artist,
      nodeStatus: sample?.nodeStatus ?? NodeStatus.normal,
      subItemsCount: directFoldersCount + directFilesCount,
      children: null,
    );
  }

  /// 应用新的排序配置并重排文件树。
  void applySort(FileSortOption option) {
    _currentSort = option;
    _sort(option);
  }

  void _sort(FileSortOption option) {
    // folder 树始终按 title 升序保持稳定（folder 无 duration/size 字段）
    rootNode.walkIncludingSelf((node) {
      final entries = node.children.entries.toList()
        ..sort((a, b) =>
            a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase()));
      node.children
        ..clear()
        ..addEntries(entries);
    });

    // 文件列表按 option.field 排序
    for (final files in folderMap.values) {
      files.sort((a, b) {
        final cmp = _compareByField(a, b, option.field);
        return option.descending ? -cmp : cmp;
      });
    }
  }

  int _compareByField(FileNode a, FileNode b, FileSortField field) {
    switch (field) {
      case FileSortField.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case FileSortField.titleNumber:
        // 优先按标题前缀序号（"1." "10." "Episode 03" 等）数值比较；
        // 解析不到序号时回退到 title 字母序，保证顺序稳定。
        final aNum = _parseLeadingNumber(a.title);
        final bNum = _parseLeadingNumber(b.title);
        if (aNum != null && bNum != null) {
          final cmp = aNum.compareTo(bNum);
          if (cmp != 0) return cmp;
        } else if (aNum != null) {
          return -1;
        } else if (bNum != null) {
          return 1;
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case FileSortField.duration:
        return (a.duration ?? 0).compareTo(b.duration ?? 0);
      case FileSortField.size:
        return (a.size ?? 0).compareTo(b.size ?? 0);
    }
  }

  /// 从 title 解析前缀数字序号。
  /// 匹配模式（不区分大小写）：
  ///   "1." "10." "001_"  → 返回 1, 10, 1
  ///   "Episode 03" "EP.12" "Track 5" "第03话"  → 返回 3, 12, 5, 3
  /// 解析不到返回 null。
  static int? _parseLeadingNumber(String title) {
    final t = title.trimLeft();
    if (t.isEmpty) return null;

    // 1) 纯数字开头（带可选分隔符 . _ - 空格）
    final numPrefix = RegExp(r'^\d+');
    final m1 = numPrefix.firstMatch(t);
    if (m1 != null) {
      // 数字后必须是分隔符或字符串结束，避免把 "100%" 之类当成序号
      final after = m1.end;
      if (after >= t.length) return int.tryParse(m1.group(0)!);
      final sep = t[after];
      if (sep == '.' || sep == '_' || sep == '-' || sep == ' ' || sep == '、') {
        return int.tryParse(m1.group(0)!);
      }
    }

    // 2) 带前缀的关键字：episode/ep/track/chapter/集/话/回
    final keywordPrefix = RegExp(
      r'^(?:ep(?:isode)?|track|chapter|ch|集|话|回)\s*[\.\-_\s]?\s*0*(\d+)',
      caseSensitive: false,
    );
    final m2 = keywordPrefix.firstMatch(t);
    if (m2 != null) return int.tryParse(m2.group(1)!);

    // 3) 中文数字前缀："第一集" "第三话" 等
    const cnDigits = '零一二三四五六七八九十百千';
    if (cnDigits.contains(t[0])) {
      final cnNum = RegExp(r'^[零一二三四五六七八九十百千]+');
      final m3 = cnNum.firstMatch(t);
      if (m3 != null) {
        final n = _chineseToInt(m3.group(0)!);
        if (n != null && n > 0) return n;
      }
    }

    return null;
  }

  /// 简单中文数字转 int（支持一到九十九，覆盖"第X集"常见场景）。
  static int? _chineseToInt(String s) {
    const digits = {
      '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
    };
    if (s.isEmpty) return null;
    if (s == '十') return 10;

    int result = 0;
    int current = 0;
    bool hasTen = false;
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '十') {
        hasTen = true;
        if (current == 0) current = 1;
        result += current * 10;
        current = 0;
      } else if (c == '百') {
        result += (current == 0 ? 1 : current) * 100;
        current = 0;
      } else if (digits.containsKey(c)) {
        current = digits[c]!;
      } else {
        return null;
      }
    }
    result += current;
    return result > 0 ? result : (hasTen ? 10 : null);
  }

  static String normalizePath(String path) {
    return NodeFolder.normalizePath(path);
  }

  static String dirName(String path) {
    return NodeFolder.dirName(path);
  }

  static String baseName(String path) {
    return NodeFolder.baseName(path);
  }

  static String joinPath(String parent, String child) {
    return NodeFolder.joinPath(parent, child);
  }

  static int _depthFromRoot(String root, String path) {
    final normalizedRoot = normalizePath(root).toLowerCase();
    final normalizedPath = normalizePath(path).toLowerCase();

    if (!normalizedPath.startsWith(normalizedRoot)) return 0;

    final relative = normalizedPath.substring(normalizedRoot.length);
    return relative.split('/').where((e) => e.isNotEmpty).length;
  }

  static void _flattenRemoteNode({
    required FileNode node,
    required String parentPath,
    required String rootPath,
    required int workId,
    required NodeSource source,
    required List<FileNode> flatNodes,
  }) {
    final nodePath = joinPath(parentPath, node.title);
    final children = node.children ?? const <FileNode>[];

    if (node.isFolder || children.isNotEmpty) {
      for (final child in children) {
        _flattenRemoteNode(
          node: child,
          parentPath: nodePath,
          rootPath: rootPath,
          workId: workId,
          source: source,
          flatNodes: flatNodes,
        );
      }
      return;
    }

    final folderPath = normalizePath(parentPath);
    final normalizedPath = normalizePath(nodePath);
    flatNodes.add(
      node.copyWith(
        children: null,
        path: normalizedPath,
        folderPath: folderPath,
        rootPath: rootPath,
        parentPath: folderPath,
        depth: _depthFromRoot(rootPath, normalizedPath),
        source: source,
        workId: workId,
      ),
    );
  }

  /// 通用树扁平化：保留节点原有 `source` / `workId`，仅补齐路径相关字段。
  static void _flattenTreeNode({
    required FileNode node,
    required String parentPath,
    required String rootPath,
    required List<FileNode> flatNodes,
  }) {
    final nodePath = joinPath(parentPath, node.title);
    final children = node.children ?? const <FileNode>[];

    if (node.isFolder || children.isNotEmpty) {
      for (final child in children) {
        _flattenTreeNode(
          node: child,
          parentPath: nodePath,
          rootPath: rootPath,
          flatNodes: flatNodes,
        );
      }
      return;
    }

    final folderPath = normalizePath(parentPath);
    final normalizedPath = normalizePath(nodePath);
    flatNodes.add(
      node.copyWith(
        children: null,
        path: normalizedPath,
        folderPath: folderPath,
        rootPath: rootPath,
        parentPath: folderPath,
        depth: _depthFromRoot(rootPath, normalizedPath),
      ),
    );
  }
}

class FolderTreeNode {
  final FolderTreeNode? parentNode;
  final NodeFolder? folder;
  final Map<NodeFolder, FolderTreeNode> children = {};

  FolderTreeNode({required this.parentNode, required this.folder});

  factory FolderTreeNode.root() {
    return FolderTreeNode(parentNode: null, folder: null);
  }

  List<NodeFolder> get foldersList => children.keys.toList();

  FolderTreeNode? lookup(NodeFolder target, {String? stopAtRootPath}) {
    FolderTreeNode current = this;

    for (final folder in target.buildInbetweenFolders(
      stopAtRootPath: stopAtRootPath,
    )) {
      final next = current.children[folder];
      if (next == null) return null;
      current = next;
    }

    return current;
  }

  void walk(void Function(FolderTreeNode node) visitor) {
    for (final child in children.values) {
      visitor(child);
      child.walk(visitor);
    }
  }

  void walkIncludingSelf(void Function(FolderTreeNode node) visitor) {
    visitor(this);
    walk(visitor);
  }
}
