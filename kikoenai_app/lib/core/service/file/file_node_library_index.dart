import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../features/file_sort/provider/file_sort_option.dart';

class FileNodeLibraryIndex {
  final String rootPath;
  final NodeSource fallbackFolderSource;

  final Map<NodeFolder, List<FileNode>> folderMap = {};
  final Map<String, FileNode> nodeByKey = {};
  final Map<String, FileNode> nodeByPath = {};

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
    required SiteContentId contentId,
    NodeSource source = NodeSource.asmrServer,
  }) {
    final rootPath = remoteRootPath(contentId);
    return FileNodeLibraryIndex(
      flatNodes: flattenRemoteTree(
        roots: roots,
        contentId: contentId,
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

  static String remoteRootPath(SiteContentId contentId) =>
      contentId.uri.toString();

  static List<FileNode> flattenRemoteTree({
    required List<FileNode> roots,
    required SiteContentId contentId,
    NodeSource source = NodeSource.asmrServer,
  }) {
    final rootPath = remoteRootPath(contentId);
    final legacyWorkId = int.tryParse(contentId.remoteId);
    final flatNodes = <FileNode>[];

    for (final node in roots) {
      _flattenRemoteNode(
        node: node,
        parentPath: rootPath,
        rootPath: rootPath,
        contentId: contentId,
        workId: legacyWorkId,
        source: source,
        flatNodes: flatNodes,
      );
    }

    return flatNodes;
  }

  NodeFolder? get currentFolder => _currentFolder;

  NodeFolder get rootFolder => NodeFolder(normalizePath(rootPath));

  bool get isHome => _currentFolder == null;

  /// Whether every indexed file is local.
  ///
  /// Empty indexes fall back to the source supplied when the index was built.
  bool get isLocalContent {
    if (nodeByKey.isNotEmpty) {
      return nodeByKey.values.every((node) => node.isLocal);
    }
    return fallbackFolderSource == NodeSource.localWork ||
        fallbackFolderSource == NodeSource.localSingle;
  }

  /// Whether the index contains at least one remotely downloadable file.
  bool get hasRemoteContent {
    if (nodeByKey.isNotEmpty) {
      return nodeByKey.values.any((node) => node.isRemote);
    }
    return fallbackFolderSource == NodeSource.asmrServer ||
        fallbackFolderSource == NodeSource.cloudDrive;
  }

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

  /// 根据音频或视频文件路径跳转到该文件所在的文件夹。
  ///
  /// 只有索引中路径完全匹配的音频/视频节点可以触发跳转。文件不存在、
  /// 节点不可播放或父文件夹不在当前索引中时返回 `false`，并保持当前位置不变。
  bool jumpToFilePath(String filePath) {
    final normalizedFilePath = normalizePath(filePath);
    final file = nodeByPath[normalizedFilePath.toLowerCase()];
    if (file == null || !file.isPlayable) return false;

    final folder = file.folder;
    if (folder == null) return false;

    if (folder.hasSamePathAs(rootPath)) {
      goHome();
      return true;
    }

    final targetNode = rootNode.lookup(
      folder,
      stopAtRootPath: normalizePath(rootPath),
    );
    if (targetNode == null) return false;

    _currentNode = targetNode;
    _currentFolder = folder;
    return true;
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

  /// 递归收集索引中所有字幕文件，返回扁平的 [FileNode] 列表。
  ///
  /// 遍历 [nodeByPath] 中已建索引的全部非文件夹节点，按
  /// [FileExtensions.isSubtitle] 过滤；返回的节点会清空 `children`，
  /// 确保是"平"的（不携带子项）。顺序不保证，调用方如需排序请自行处理。
  List<FileNode> collectAllSubtitles() {
    final result = <FileNode>[];
    for (final node in nodeByPath.values) {
      final path = node.path;
      if (path != null && FileExtensions.isSubtitle(path)) {
        result.add(node.copyWith(children: null));
      }
    }
    return result;
  }

  /// 递归遍历 folder 树，依次访问每个 folder 节点（含其本身）。
  ///
  /// [visit] 接收当前 folder 的 [NodeFolder] 与其在 [folderMap] 中的直接文件列表。
  void walkFolders(
    void Function(NodeFolder folder, List<FileNode> directFiles) visit,
  ) {
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
      nodeByPath[normalizedNode.effectivePath.toLowerCase()] = normalizedNode;
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
    // 默认排序：不进行任何处理，保持接口/扫描返回顺序
    if (option.field == FileSortField.defaultSort) return;

    // 文件夹没有 duration/size，这两种模式下继续按标题升序。
    // 标题和标题序号模式则与文件使用相同规则，否则纯文件夹目录会看起来“排序失效”。
    rootNode.walkIncludingSelf((node) {
      final entries = node.children.entries.toList()
        ..sort((a, b) {
          final cmp = option.field == FileSortField.titleNumber
              ? _compareTitlesByNumber(a.key.name, b.key.name)
              : _compareTitles(a.key.name, b.key.name);
          final followsDirection =
              option.field == FileSortField.title ||
              option.field == FileSortField.titleNumber;
          return option.descending && followsDirection ? -cmp : cmp;
        });
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
      case FileSortField.defaultSort:
        return 0;
      case FileSortField.title:
        return _compareTitles(a.title, b.title);
      case FileSortField.titleNumber:
        return _compareTitlesByNumber(
          a.title,
          b.title,
          stripKnownFileExtension: true,
        );
      case FileSortField.duration:
        return (a.duration ?? 0).compareTo(b.duration ?? 0);
      case FileSortField.size:
        return (a.size ?? 0).compareTo(b.size ?? 0);
    }
  }

  static int _compareTitles(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  static int _compareTitlesByNumber(
    String a,
    String b, {
    bool stripKnownFileExtension = false,
  }) {
    final normalizedA = _normalizeNumericTitle(
      a,
      stripKnownFileExtension: stripKnownFileExtension,
    );
    final normalizedB = _normalizeNumericTitle(
      b,
      stripKnownFileExtension: stripKnownFileExtension,
    );
    final aSequence = _extractTitleSequence(normalizedA);
    final bSequence = _extractTitleSequence(normalizedB);

    if (aSequence != null && bSequence != null) {
      final sequenceCmp = aSequence.compareTo(bSequence);
      if (sequenceCmp != 0) return sequenceCmp;
    } else if (aSequence != null) {
      return -1;
    } else if (bSequence != null) {
      return 1;
    }

    final naturalCmp = _compareNaturally(normalizedA, normalizedB);
    if (naturalCmp != 0) return naturalCmp;
    return _compareTitles(a.toLowerCase(), b.toLowerCase());
  }

  /// 按优先级提取标题中最可能的序号：序号关键字、中日文“第 N 话”、
  /// 装饰后的开头数字、独立数字，最后才使用任意位置的数字作为兼容兜底。
  static BigInt? _extractTitleSequence(String title) {
    final labeled = _labeledSequencePattern.firstMatch(title);
    if (labeled != null && !_isPercentage(title, labeled.end)) {
      return BigInt.tryParse(labeled.group(1)!);
    }

    final ordinal = _ordinalSequencePattern.firstMatch(title);
    if (ordinal != null) return BigInt.tryParse(ordinal.group(1)!);

    final leading = _leadingSequencePattern.firstMatch(title);
    if (leading != null && !_isPercentage(title, leading.end)) {
      return BigInt.tryParse(leading.group(1)!);
    }

    for (final match in _standaloneSequencePattern.allMatches(title)) {
      if (!_isPercentage(title, match.end)) {
        return BigInt.tryParse(match.group(1)!);
      }
    }

    for (final match in _numberPattern.allMatches(title)) {
      if (!_isPercentage(title, match.end)) {
        return BigInt.tryParse(match.group(0)!);
      }
    }
    return null;
  }

  /// 序号相同时继续比较标题中的后续数字段，例如 1-2 会排在 1-10 之前。
  /// 数字通过有效位数和文本比较，不转换成 int，因此不会溢出。
  static int _compareNaturally(String a, String b) {
    final aParts = _naturalPartPattern.allMatches(a).map((m) => m.group(0)!);
    final bParts = _naturalPartPattern.allMatches(b).map((m) => m.group(0)!);
    final aIterator = aParts.iterator;
    final bIterator = bParts.iterator;

    while (true) {
      final hasA = aIterator.moveNext();
      final hasB = bIterator.moveNext();
      if (!hasA || !hasB) {
        if (hasA) return 1;
        if (hasB) return -1;
        return _compareTitles(a, b);
      }

      final aPart = aIterator.current;
      final bPart = bIterator.current;
      final aIsNumber = _isAsciiDigit(aPart.codeUnitAt(0));
      final bIsNumber = _isAsciiDigit(bPart.codeUnitAt(0));
      int cmp;
      if (aIsNumber && bIsNumber) {
        cmp = _compareNumericText(aPart, bPart);
      } else if (aIsNumber != bIsNumber) {
        cmp = aIsNumber ? -1 : 1;
      } else {
        cmp = aPart.compareTo(bPart);
      }
      if (cmp != 0) return cmp;
    }
  }

  static int _compareNumericText(String a, String b) {
    final significantA = a.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final significantB = b.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final lengthCmp = significantA.length.compareTo(significantB.length);
    if (lengthCmp != 0) return lengthCmp;
    return significantA.compareTo(significantB);
  }

  static String _normalizeNumericTitle(
    String title, {
    bool stripKnownFileExtension = false,
  }) {
    final buffer = StringBuffer();
    for (final rune in title.toLowerCase().runes) {
      if (rune >= 0xff10 && rune <= 0xff19) {
        buffer.writeCharCode(rune - 0xfee0);
      } else {
        buffer.writeCharCode(rune);
      }
    }

    var normalized = buffer.toString();
    if (stripKnownFileExtension) {
      final extension = _knownFileExtensions.firstWhere(
        normalized.endsWith,
        orElse: () => '',
      );
      if (extension.isNotEmpty) {
        normalized = normalized.substring(
          0,
          normalized.length - extension.length,
        );
      }
    }

    return normalized.replaceAllMapped(_chineseOrdinalPattern, (match) {
      final value = _chineseToInt(match.group(1)!);
      return value == null ? match.group(0)! : '第$value${match.group(2)!}';
    });
  }

  static bool _isPercentage(String title, int numberEnd) {
    var index = numberEnd;
    while (index < title.length && title[index].trim().isEmpty) {
      index++;
    }
    return index < title.length && (title[index] == '%' || title[index] == '％');
  }

  static bool _isAsciiDigit(int codeUnit) =>
      codeUnit >= 0x30 && codeUnit <= 0x39;

  static final RegExp _labeledSequencePattern = RegExp(
    r'(?:^|[^a-z0-9])(?:episode|ep|track|trk|chapter|chap|ch|part|pt|disc|disk|cd|volume|vol|scene|file|no|音轨|音軌|トラック|チャプター)\s*(?:no\.?\s*)?[#._:\-]?\s*0*(\d+)',
    caseSensitive: false,
  );
  static final RegExp _ordinalSequencePattern = RegExp(
    r'第\s*0*(\d+)\s*(?:集|话|話|章|回|幕|轨|軌|首)',
  );
  static final RegExp _leadingSequencePattern = RegExp(
    r'^\s*[\[\(\{（【「『]?\s*0*(\d+)',
  );
  static final RegExp _standaloneSequencePattern = RegExp(
    r'(?:^|[^a-z0-9])0*(\d+)(?=$|[^a-z0-9])',
    caseSensitive: false,
  );
  static final RegExp _numberPattern = RegExp(r'\d+');
  static final RegExp _naturalPartPattern = RegExp(r'\d+|\D+');
  static final RegExp _chineseOrdinalPattern = RegExp(
    r'第([零〇一二两三四五六七八九十百千]+)(集|话|話|章|回|幕|轨|軌|首)',
  );
  static final Set<String> _knownFileExtensions = {
    ...FileExtensions.archives,
    ...FileExtensions.subtitles,
    ...FileExtensions.images,
    ...FileExtensions.video,
    ...FileExtensions.audio,
    ...FileExtensions.documents,
  };

  /// 中文数字转 int（支持零到九千九百九十九）。
  static int? _chineseToInt(String s) {
    const digits = {
      '零': 0,
      '〇': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };
    if (s.isEmpty) return null;
    int result = 0;
    int current = 0;
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      final unit = switch (c) {
        '十' => 10,
        '百' => 100,
        '千' => 1000,
        _ => null,
      };
      if (unit != null) {
        result += (current == 0 ? 1 : current) * unit;
        current = 0;
      } else if (digits.containsKey(c)) {
        current = digits[c]!;
      } else {
        return null;
      }
    }
    result += current;
    return result;
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
    required SiteContentId contentId,
    required int? workId,
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
          contentId: contentId,
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
        siteId: contentId.siteId,
        remoteId: contentId.remoteId,
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
