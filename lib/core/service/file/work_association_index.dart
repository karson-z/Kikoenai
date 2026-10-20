import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../../storage/hive_storage.dart';

/// 读时关联：把本地扫描文件映射回 DL 作品 id。
///
/// 采用两层按需缓存，避免在扫描阶段写入 `workId`（网盘无法写时关联）：
///
/// - [workIdForPath] / [workIdForNode]：只沿文件夹路径向上解析最近的一个
///   RJ 目录，用于点击播放、云盘当前目录等单点场景。不会触发全量扫描。
/// - [filesForWork]：首次需要"某作品的全部本地文件"时（DL 详情本地来源、
///   本地字幕匹配）构建一次 `workId -> files` 索引。
///
/// 索引在 scanner [Box] 发生任何写入/删除时自动失效（扫描、静默同步、
/// 删除路径都会触发），也可以显式调用 [invalidate]。
class WorkAssociationIndex {
  WorkAssociationIndex._();

  static final WorkAssociationIndex instance = WorkAssociationIndex._();

  Map<int, List<FileNode>>? _filesByWork;
  final Map<String, int?> _pathWorkCache = {};
  ValueListenable<Box<FileNode>>? _scannerListenable;
  Box<FileNode>? _listenedBox;

  /// 清空两层缓存；下一次读取会按需重建。
  void invalidate() {
    _filesByWork = null;
    _pathWorkCache.clear();
  }

  /// 预构建 `workId -> files` 索引，可在扫描完成后调用。
  void warmUp() {
    _ensureBuilt();
  }

  /// 解析单个文件所属的 DL 作品 id。
  ///
  /// 优先取所在文件夹链上最近的 RJ 目录；单文件作品（文件名本身带 RJ）
  /// 作为兜底。不会触发全量索引构建。
  int? workIdForNode(FileNode node) {
    if (node.isFolder) {
      final own = RjCode.parse(node.title);
      if (own != null) return own;
    }
    final folder =
        node.folderPath ??
        (node.path == null ? null : NodeFolder.dirName(node.path!));
    final byFolder = workIdForPath(folder);
    if (byFolder != null) return byFolder;
    if (node.isFolder) return null;
    return RjCode.parse(node.title);
  }

  /// 从文件夹路径（本身或祖先）解析 RJ 编号，带路径级缓存。
  int? workIdForPath(String? folderPath) {
    if (folderPath == null || folderPath.isEmpty) return null;
    _ensureListening();
    final key = _normalize(folderPath);
    if (_pathWorkCache.containsKey(key)) return _pathWorkCache[key];
    final id = _resolveWorkId(key);
    _pathWorkCache[key] = id;
    return id;
  }

  /// [workId] 对应的全部本地文件（不含文件夹节点）。
  ///
  /// 首次调用会构建全量索引；后续为 O(1) 查表。
  List<FileNode> filesForWork(int workId) {
    if (!_ensureBuilt()) return const <FileNode>[];
    return List<FileNode>.unmodifiable(
      _filesByWork![workId] ?? const <FileNode>[],
    );
  }

  /// 构建 `workId -> files` 索引；返回 false 表示 storage 尚未就绪。
  bool _ensureBuilt() {
    if (_filesByWork != null) return true;
    _ensureListening();

    final box = _scannerBoxOrNull();
    if (box == null || !box.isOpen) return false;

    final byWork = <int, List<FileNode>>{};
    final folderCache = <String, int?>{};
    try {
      for (final node in box.values) {
        if (node.isFolder) continue;

        final folder =
            node.folderPath ??
            (node.path == null ? '' : NodeFolder.dirName(node.path!));
        final key = _normalize(folder);

        int? workId;
        if (folderCache.containsKey(key)) {
          workId = folderCache[key];
        } else {
          workId = _resolveWorkId(key);
          folderCache[key] = workId;
          _pathWorkCache.putIfAbsent(key, () => workId);
        }

        // 单文件作品：文件名本身带 RJ 时也能关联。
        workId ??= RjCode.parse(node.title);
        // 最后才回退旧缓存里可能存在的 workId，保证读时解析优先。
        workId ??= node.workId;
        if (workId == null) continue;

        byWork.putIfAbsent(workId, () => <FileNode>[]).add(node);
      }
    } catch (_) {
      // Box 已被关闭/替换：本次构建作废，下次读取重试。
      invalidate();
      return false;
    }

    _filesByWork = byWork;
    return true;
  }

  void _ensureListening() {
    final box = _scannerBoxOrNull();
    if (box == null || !box.isOpen) return;
    if (identical(_listenedBox, box)) return;

    _listenedBox = box;
    final listenable = box.listenable();
    _scannerListenable?.removeListener(_handleScannerBoxChanged);
    _scannerListenable = listenable;
    listenable.addListener(_handleScannerBoxChanged);
    // box 被替换时，旧缓存不再可信。
    invalidate();
  }

  void _handleScannerBoxChanged() => invalidate();

  Box<FileNode>? _scannerBoxOrNull() {
    try {
      return AppStorage.scannerBox;
    } catch (_) {
      // Hive 尚未初始化（测试或冷启动早期），按空索引处理。
      return null;
    }
  }

  static String _normalize(String path) =>
      NodeFolder.normalizePath(path).toLowerCase();

  /// 从 `folderPath` 自身开始逐级向上找第一个含 RJ 的文件夹名。
  static int? _resolveWorkId(String normalizedFolderPath) {
    var end = normalizedFolderPath.length;
    while (end > 0) {
      final slash = normalizedFolderPath.lastIndexOf('/', end - 1);
      final start = slash + 1;
      if (start < end) {
        final id = RjCode.parse(normalizedFolderPath.substring(start, end));
        if (id != null) return id;
      }
      if (slash <= 0) break;
      end = slash;
    }
    return null;
  }
}
