import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';

abstract class FileScannerService {
  ScanMode get scanMode;
  Stream<List<FileNode>> get result;
  bool get isReady;

  ///开始扫描的方法
  Future<void> startScan(String path);

  ///停止扫描的方法
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

/// 增加一个基类处理通用逻辑
abstract class _BaseFileScanner implements FileScannerService {
  final _resultController = StreamController<List<FileNode>>.broadcast();
  bool _isReady = false;

  // 用于存储已扫描到的节点，实现增量更新
  final List<FileNode> _scannedNodes = [];

  @override
  Stream<List<FileNode>> get result => _resultController.stream;

  @override
  bool get isReady => _isReady;

  @protected
  void updateResult(List<FileNode> nodes) {
    _scannedNodes.addAll(nodes);
    _resultController.add(List.from(_scannedNodes)); // 发送副本防止引用污染
  }

  /// 通用的递归扫描逻辑
  @protected
  Future<void> performScan(String path, Set<String> extensions) async {
    _isReady = false;
    _scannedNodes.clear();
    final dir = Directory(path);
    if (!await dir.exists()) {
      _isReady = true;
      return;
    }
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (extensions.contains(ext)) {
            final node = FileNode(
              mediaStreamUrl: entity.path,
              mediaDownloadUrl: entity.path,
              type: scanMode == ScanMode.video ? NodeType.video : (scanMode == ScanMode.audio ? NodeType.audio : NodeType.text),
              title: entity.path.split(Platform.pathSeparator).last,
            );
            updateResult([node]);
          }
        }
      }
    } catch (e) {
      _resultController.addError(e);
    } finally {
      _isReady = true;
    }
  }
  @override
  void dispose() {
    _resultController.close();
  }
}
class _AudioFileScannerServiceImpl extends _BaseFileScanner {
  @override
  ScanMode get scanMode => ScanMode.audio;

  @override
  Future<void> startScan(String path) async {
    // 常见的音频格式
    const extensions = FileExtensions.audio;
    await performScan(path, extensions);
  }
}
class _VideoFileScannerServiceImpl extends _BaseFileScanner {

  @override
  ScanMode get scanMode => ScanMode.video;

  @override
  Future<void> startScan(String path) async {
    // 常见的视频格式
    const extensions = FileExtensions.video;
    await performScan(path, extensions);
  }

}
class _LyricFileScannerServiceImpl extends _BaseFileScanner {
  @override
  ScanMode get scanMode => ScanMode.subtitles;

  @override
  Future<void> startScan(String path) async {
    // 常见的视频格式
    const extensions = FileExtensions.subtitles;
    await performScan(path, extensions);
  }
}



