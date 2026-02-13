import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';

import 'archive_service.dart';

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
  Future<void> performScan(String path, Set<String> extensions, {bool scanArchives = true}) async {
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
          final filePath = entity.path;
          if (!filePath.contains('.')) continue;
          // 获取后缀名（包含 . 符号，方便与 ArchiveService 逻辑统一）
          final extWithDot = filePath.substring(filePath.lastIndexOf('.')).toLowerCase();
          // 获取纯后缀名（用于 extensions 匹配）
          final ext = extWithDot.replaceFirst('.', '');
          // --- 逻辑 A: 处理普通媒体文件 ---
          if (extensions.contains(ext)) {
            final node = _createFileNode(entity.path, scanMode);
            updateResult([node]);
          }
          // --- 逻辑 B: 处理压缩包文件 ---
          // 仅当开启压缩包扫描且文件是合法的压缩格式时处理
          else if (scanArchives && ArchiveService.isArchive(filePath)) {
            try {
              final entries = ArchiveService.scanZip(entity, allowedExts: extensions);
              for (var entry in entries) {
                final zipNode = _createFileNode(entry.virtualPath,scanMode);
                updateResult([zipNode]);
              }
            } catch (e) {
              debugPrint("ScannerService: 压缩包解析失败 $filePath - $e");
            }
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
  FileNode _createFileNode(String path, ScanMode mode) {
    return FileNode(
      mediaStreamUrl: path,
      mediaDownloadUrl: path,
      type: _mapScanModeToNodeType(mode),
      title: path.split(Platform.pathSeparator).last,
    );
  }

  /// 将扫描模式转换为节点类型
  NodeType _mapScanModeToNodeType(ScanMode mode) {
    switch (mode) {
      case ScanMode.video:
        return NodeType.video;
      case ScanMode.audio:
        return NodeType.audio;
      case ScanMode.subtitles:
        return NodeType.text;
      }
  }
}
//音视频不允许从压缩包中读取
class _AudioFileScannerServiceImpl extends _BaseFileScanner {
  @override
  ScanMode get scanMode => ScanMode.audio;

  @override
  Future<void> startScan(String path) async {
    // 常见的音频格式
    const extensions = FileExtensions.audio;
    await performScan(path, extensions,scanArchives: false);
  }
}
class _VideoFileScannerServiceImpl extends _BaseFileScanner {

  @override
  ScanMode get scanMode => ScanMode.video;

  @override
  Future<void> startScan(String path) async {
    // 常见的视频格式
    const extensions = FileExtensions.video;
    await performScan(path, extensions,scanArchives: false);
  }

}
// 字幕允许从压缩包中提取
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



