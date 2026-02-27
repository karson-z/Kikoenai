import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'file_scanner_worker.dart';
import 'file_tree_builder.dart';


enum ScanMode { audio, video, subtitles }


abstract class FileScannerService {
  ScanMode get scanMode;

  /// 输出完整的文件列表流
  Stream<List<FileNode>> get result;

  /// 当前是否就绪
  bool get isReady;

  /// 暴露状态流给 UI
  Stream<WorkerState> get stateStream;

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

abstract class _BaseFileScanner implements FileScannerService {
  // 组合 Worker
  final _worker = FileScanWorker();

  final _resultController = StreamController<List<FileNode>>.broadcast();

  final _treeBuilder = IncrementalTreeBuilder();

  @override
  Stream<List<FileNode>> get result => _resultController.stream;

  @override
  Stream<WorkerState> get stateStream => _worker.stateStream;

  @override
  bool get isReady => _worker.currentState != WorkerState.scanning;

  @override
  @mustCallSuper
  void dispose() {
    _worker.dispose();
    _resultController.close();
  }

  /// 通用的扫描入口
  @protected
  Future<void> performScan(String path, Set<String> extensions, {bool scanArchives = true}) async {
    // 1. 重置数据
    _treeBuilder.clear();
    _treeBuilder.setRootPath(path);
    _resultController.add([]);

    // 2. 启动 Worker
    final chunkStream = _worker.start(
      path: path,
      extensions: extensions,
      scanMode: scanMode,
      scanArchives: scanArchives,
    );

    // Worker 发送的是一块块的数据 (Chunk)，我们需要把它们拼起来发给 UI
    chunkStream.listen((flatChunk) {

      // 将这一批扁平节点合并进树
      _treeBuilder.mergeChunk(flatChunk);

      // 发送树的根节点列表给 UI
      // UI 拿到 roots 后，通过 ListView 渲染第一层，点击文件夹再展开 children
      _resultController.add(List.of(_treeBuilder.roots));

    });
  }
}


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


