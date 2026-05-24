import 'package:path/path.dart' as p;
import '../../model/file_node.dart';

class FileNodeLibraryIndex {
  final String rootPath;
  final NodeSource fallbackFolderSource;

  final Map<NodeFolder, List<FileNode>> folderMap = {};
  final Map<String, FileNode> nodeByKey = {};

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
    return [
      ...folders,
      ...currentFiles,
    ];
  }

  void stepIn(NodeFolder folder) {
    final next = _currentNode.children[folder] ??
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

  List<FileNode> getFilesInFolder(NodeFolder folder, {bool recursive = false}) {
    if (!recursive) return folderMap[folder] ?? const [];

    final node = rootNode.lookup(folder, stopAtRootPath: rootPath);
    if (node == null) return folderMap[folder] ?? const [];

    final files = <FileNode>[
      ...folderMap[folder] ?? const [],
    ];

    node.walk((child) {
      final folder = child.folder;
      if (folder != null) {
        files.addAll(folderMap[folder] ?? const []);
      }
    });

    return files;
  }

  List<FileNode> toTreeChildren() {
    return _childrenFor(rootNode);
  }

  List<FileNode> _childrenFor(FolderTreeNode treeNode) {
    final folders = treeNode.foldersList.map((folder) {
      final child = treeNode.children[folder];
      return _folderToFileNode(folder).copyWith(
        children: child == null ? const [] : _childrenFor(child),
      );
    });

    final files = folderMap[treeNode.folder ?? rootFolder] ?? const [];

    return [
      ...folders,
      ...files,
    ];
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

      for (final part in folder.buildInbetweenFolders(stopAtRootPath: normalizedRoot)) {
        current = current.children.putIfAbsent(
          part,
              () => FolderTreeNode(parentNode: current, folder: part),
        );
      }
    }

    _sort();
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
    final treeNode = rootNode.lookup(folder, stopAtRootPath: normalizePath(rootPath));
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

      // ==========================================
      // 【正解】：让属性回归本质
      // ==========================================
      subItemsCount: directFoldersCount + directFilesCount,
      children: null, // 干净利落，不带任何累赘
    );
  }

  void _sort() {
    for (final files in folderMap.values) {
      files.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    rootNode.walkIncludingSelf((node) {
      final entries = node.children.entries.toList()
        ..sort((a, b) => a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase()));
      node.children
        ..clear()
        ..addEntries(entries);
    });
  }

  static String normalizePath(String path) {
    final posix = p.Context(style: p.Style.posix);
    return posix.normalize(path.replaceAll('\\', '/'));
  }

  static String dirName(String path) {
    final posix = p.Context(style: p.Style.posix);
    return posix.dirname(path);
  }

  static int _depthFromRoot(String root, String path) {
    final normalizedRoot = normalizePath(root).toLowerCase();
    final normalizedPath = normalizePath(path).toLowerCase();

    if (!normalizedPath.startsWith(normalizedRoot)) return 0;

    final relative = normalizedPath.substring(normalizedRoot.length);
    return relative.split('/').where((e) => e.isNotEmpty).length;
  }
}

class FolderTreeNode {
  final FolderTreeNode? parentNode;
  final NodeFolder? folder;
  final Map<NodeFolder, FolderTreeNode> children = {};

  FolderTreeNode({
    required this.parentNode,
    required this.folder,
  });

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
