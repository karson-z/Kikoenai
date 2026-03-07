import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import '../../utils/scraper/scraper_storage.dart';
import 'file_scanner_storage.dart';
import 'file_scanner_worker.dart';
import 'file_tree_builder.dart';
import 'package:path/path.dart' as p;

enum ScanMode { audio, video, subtitles }

abstract class FileScannerService {
  /// 扫描模式
  ScanMode get scanMode;

  /// 输出完整的文件列表流
  Stream<List<FileNode>> get result;

  /// 暴露状态流给 UI (扫描中/空闲/完成)
  Stream<WorkerState> get stateStream;

  /// 启动扫描（包含加载缓存和后台同步）
  Future<void> startScan(String path);

  void dispose();

  factory FileScannerService(ScanMode scanMode) {
    switch (scanMode) {
      case ScanMode.audio:
        return _AudioFileScannerServiceImpl();
      case ScanMode.video:
        return _VideoFileScannerServiceImpl();
      case ScanMode.subtitles:
        return _LyricFileScannerServiceImpl();
    }
  }
}
/// 基类，固定一整套扫描流程
abstract class _BaseFileScanner implements FileScannerService {
  // 组合 Worker
  final _worker = FileScanWorker();

  // 结果流控制器
  final _resultController = StreamController<List<FileNode>>.broadcast();

  // 内存树构建器
  final _treeBuilder = IncrementalTreeBuilder();

  // 数据存储层
  final _storage = FileScannerStorage();

  // 记录本次扫描访问过的路径 (用于标记清除算法检测删除的文件)
  final Set<String> _visitedPaths = {};

  @override
  Stream<List<FileNode>> get result => _resultController.stream;

  @override
  Stream<WorkerState> get stateStream => _worker.stateStream;

  @override
  @mustCallSuper
  void dispose() {
    _worker.dispose();
    _resultController.close();
  }

  /// 通用的扫描入口
  @protected
  Future<void> performScan(String path, Set<String> extensions, {bool scanArchives = true}) async {
    // 1.先加载缓存，让用户立马看到界面
    // 当用户从未扫描过（缓存没有数据）则自然而然的进入静默后台扫描。
    // await 确保 UI 在后台扫描开始前先显示旧数据
    await _initAndLoadCache(path);

    // 2. 开启后台 Worker 进行“纠错” (增量同步)
    // 静默扫描开启会去
    _performSilentSync(path, extensions, scanArchives: scanArchives);
  }

  /// 步骤 1: 从 DB 加载缓存并构建 UI 树
  Future<void> _initAndLoadCache(String rootPath) async {
    // 重置 Builder 状态
    _treeBuilder.clear(keepRootPath: false);
    _treeBuilder.setRootPath(rootPath);

    // 直接通过 Storage 获取该路径下的所有缓存节点
    final cachedNodes = _storage.getNodesByRootPath(rootPath);

    if (cachedNodes.isNotEmpty) {
      // 构建内存树
      _treeBuilder.mergeChunk(cachedNodes);
      // 推送给 UI
      _resultController.add(List.of(_treeBuilder.roots));
    }
  }

  /// 步骤 2: 后台执行扫描并同步差异
  Future<void> _performSilentSync(String path, Set<String> extensions, {required bool scanArchives}) async {
    _visitedPaths.clear();
    final allParsedWorks = ScraperStorage().getAllWorks();
    final parsedRjCodes = allParsedWorks.expand((w) => [
      'RJ${w.id}'.toUpperCase(),
      'RJ0${w.id}'.toUpperCase()
    ]).toSet();
    // 启动 Worker
    final chunkStream = _worker.start(
      parsedRjCodes: parsedRjCodes,
      path: path,
      extensions: extensions,
      scanMode: scanMode,
      scanArchives: scanArchives,
    );

    /// 监听 Worker 发回来的实时文件流
    /// 由于Worker 中扫描后传递回来的数据是裸数据（单纯的扫描文件）,那么添加至扫描白名单[_visitedPaths]这里的数据永远只有文件
    /// 如果只把文件添加至白名单就会出现扫描完成后，清除不存在数据时把构建好或解析完成的文件夹目录删除
    /// 所以必须使用_markPathAndParentsAsVisited 将其父级目录一并添加至白名单中。
    /// 只要文件夹里还有一个有效文件，文件夹的路径就会被 _markPathAndParentsAsVisited 保护，其状态（已解析/待解析）安全无恙。
    /// 如果用户删除了整个作品文件夹，里面没有任何文件了，该文件夹路径不会进入白名单，最终会被 _handleDeletedFiles 连带业务状态一起从 Hive 中干净地抹除。
    /// 采用 await for 保证其顺序执行，避免竞态的产生
    await for (final flatChunk in chunkStream) {
      final List<FileNode> filesToUpdate = [];

      for (var node in flatChunk) {
        _markPathAndParentsAsVisited(node.keyId, path);
        final cachedNode = _storage.getNode(node.keyId);

        if (cachedNode == null ||
            cachedNode.lastModified != node.lastModified ||
            cachedNode.nodeStatus != node.nodeStatus ||
            cachedNode.rjCode != node.rjCode) {
          filesToUpdate.add(node);
        }
      }
      if (filesToUpdate.isNotEmpty) {
        _treeBuilder.mergeChunk(filesToUpdate);
        final nodesToSaveToDb = _treeBuilder.consumeTouchedNodes();
        await _storage.saveNodes(nodesToSaveToDb); // 等待落盘完成
        _resultController.add(List.of(_treeBuilder.roots));
      }
    }

    // 当流真正结束（所有 await 都执行完毕）后，才会走到这里
    // D. 清除 ：处理被删除的文件
    await _handleDeletedFiles(path);
  }

  /// 步骤 3: 处理删除逻辑 (Mark & Sweep 的 Sweep 阶段)
  Future<void> _handleDeletedFiles(String rootPath) async {
    final allCachedNodes = _storage.getNodesByRootPath(rootPath);
    final List<String> keysToDelete = [];

    for (var node in allCachedNodes) {
      // 同样使用 p.normalize 进行结构化对齐
      final normalizedKey = p.normalize(node.keyId).toLowerCase();

      if (!_visitedPaths.contains(normalizedKey)) {
        keysToDelete.add(node.keyId); // 删除依然用原始 key
      }
    }

    if (keysToDelete.isNotEmpty) {
      debugPrint("Scanner: Detected ${keysToDelete.length} deleted files. Cleaning up...");
      await _storage.deleteNodes(keysToDelete);

      final remainingNodes = _storage.getNodesByRootPath(rootPath);
      _treeBuilder.rebuild(remainingNodes);
      _resultController.add(List.of(_treeBuilder.roots));
    }
  }

  //递归获取所有父级路径，加入白名单
  void _markPathAndParentsAsVisited(String fullPath, String rootPath) {
    String currentPath = p.normalize(fullPath).toLowerCase();
    final String lowerRoot = p.normalize(rootPath).toLowerCase();

    while (true) {
      _visitedPaths.add(currentPath);
      // 退出条件 1: 退到了你指定的扫描根目录
      // 退出条件 2: 退到了系统的顶级目录 (例如 p.dirname("C:\") 依然是 "C:\")，防止死循环
      if (currentPath == lowerRoot || currentPath == p.dirname(currentPath)) {
        break;
      }
      // 核心替换：直接用 p.dirname 安全获取上一级目录，告别 substring 和 lastIndexOf
      currentPath = p.dirname(currentPath);
    }
  }
}
/// 下方三个文件为不同策略，根据模式的不同选择的模式就不同
class _AudioFileScannerServiceImpl extends _BaseFileScanner {
  @override
  ScanMode get scanMode => ScanMode.audio;

  @override
  Future<void> startScan(String path) async {
    await performScan(path, FileExtensions.audio, scanArchives: false);
  }
}

class _VideoFileScannerServiceImpl extends _BaseFileScanner {
  @override
  ScanMode get scanMode => ScanMode.video;

  @override
  Future<void> startScan(String path) async {
    await performScan(path, FileExtensions.video, scanArchives: false);
  }
}

class _LyricFileScannerServiceImpl extends _BaseFileScanner {
  @override
  ScanMode get scanMode => ScanMode.subtitles;

  @override
  Future<void> startScan(String path) async {
    // 字幕通常允许扫描压缩包
    await performScan(path, FileExtensions.subtitles, scanArchives: true);
  }
}