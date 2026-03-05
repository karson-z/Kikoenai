import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'file_scanner_storage.dart';
import 'file_scanner_worker.dart';
import 'file_tree_builder.dart';

enum ScanMode { audio, video, subtitles }

abstract class FileScannerService {
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

    // 启动 Worker
    final chunkStream = _worker.start(
      path: path,
      extensions: extensions,
      scanMode: scanMode,
      scanArchives: scanArchives,
    );

    // 监听 Worker 发回来的实时文件流
    chunkStream.listen((flatChunk) async {
      final List<FileNode> filesToUpdate = [];

      for (var node in flatChunk) {
        _visitedPaths.add(node.keyId);
        final cachedNode = _storage.getNode(node.keyId);
        if (cachedNode == null ||
            cachedNode.lastModified != node.lastModified) {
          filesToUpdate.add(node);
        }
      }

      if (filesToUpdate.isNotEmpty) {
        // 1. 将物理层扫描到的裸文件喂给 Builder
        // Builder 会在内部组装树结构，赋予文件夹 NodeStatus，并统筹所有变更节点
        _treeBuilder.mergeChunk(filesToUpdate);

        // 2. 一次性提取包括文件、以及动态生成的带状态的文件夹
        final nodesToSaveToDb = _treeBuilder.consumeTouchedNodes();

        // 3. 将加工完毕的数据持久化，确保业务状态落盘
        await _storage.saveNodes(nodesToSaveToDb);

        // 4. 驱动 UI 更新
        _resultController.add(List.of(_treeBuilder.roots));
      }
    }, onDone: () {
      // D. 清除 ：处理被删除的文件
      _handleDeletedFiles(path);
    });
  }

  /// 步骤 3: 处理删除逻辑 (Mark & Sweep 的 Sweep 阶段)
  Future<void> _handleDeletedFiles(String rootPath) async {
    // 1. 获取数据库中该路径下目前所有的文件
    final allCachedNodes = _storage.getNodesByRootPath(rootPath);

    final List<String> keysToDelete = [];

    // 2. 遍历缓存
    for (var node in allCachedNodes) {
      // 如果缓存里的文件，在刚才的扫描中没出现 (_visitedPaths)，说明物理文件被删了
      if (!_visitedPaths.contains(node.keyId)) {
        keysToDelete.add(node.keyId);
      }
    }

    // 3. 执行删除和重构
    if (keysToDelete.isNotEmpty) {
      debugPrint("Scanner: Detected ${keysToDelete.length} deleted files. Cleaning up...");

      // A. 从数据库删除
      await _storage.deleteNodes(keysToDelete);

      // B. 重构 UI
      // 从内存中获取数据后重建树
      final remainingNodes = _storage.getNodesByRootPath(rootPath);

      _treeBuilder.rebuild(remainingNodes);

      _resultController.add(List.of(_treeBuilder.roots));
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