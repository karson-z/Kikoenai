import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'archive_service.dart';
import 'file_scanner_service.dart';
enum WorkerState {
  idle,     // 初始/空闲状态
  scanning, // 正在扫描中
  done,     // 扫描正常完成 (Terminal State)
  error,    // 扫描因错误终止 (Terminal State)
}
/// 传递给 Isolate 的配置参数 (DTO)
class _WorkerConfig {
  final String rootPath;
  final Set<String> extensions;
  final bool scanArchives;
  final ScanMode scanMode;
  final SendPort sendPort;

  _WorkerConfig({
    required this.rootPath,
    required this.extensions,
    required this.scanArchives,
    required this.scanMode,
    required this.sendPort,
  });
}

/// 专用的 Worker 类，负责管理 Isolate 生命周期和数据流
class FileScanWorker {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  StreamController<List<FileNode>>? _resultController;

  // 状态流 (WorkerState)
  final _stateController = StreamController<WorkerState>.broadcast();
  WorkerState _currentState = WorkerState.idle;

  WorkerState get currentState => _currentState;
  Stream<WorkerState> get stateStream => _stateController.stream;

  /// 开始扫描
  Stream<List<FileNode>> start({
    required String path,
    required Set<String> extensions,
    required ScanMode scanMode,
    bool scanArchives = false,
  }) {
    // 强制清理之前的资源，确认为 Idle 状态
    _releaseResources();

    // 1. 状态流转 -> Scanning
    _updateState(WorkerState.scanning);

    _resultController = StreamController<List<FileNode>>();
    _receivePort = ReceivePort();

    final config = _WorkerConfig(
      rootPath: path,
      extensions: extensions,
      scanArchives: scanArchives,
      scanMode: scanMode,
      sendPort: _receivePort!.sendPort,
    );

    _spawnIsolate(config);

    return _resultController!.stream;
  }

  /// 手动停止/重置
  /// 通常用于用户点击“取消”按钮，或者页面销毁
  void dispose() {
    _releaseResources();
    // 手动停止视为回到 Idle 状态
    _updateState(WorkerState.idle);
  }

  /// 仅释放资源（Isolate/Port），但不改变状态为 Idle
  /// 用于 Done/Error 状态保留现场
  void _releaseResources() {
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _resultController?.close();

    _isolate = null;
    _receivePort = null;
    _resultController = null;
  }

  void _updateState(WorkerState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  Future<void> _spawnIsolate(_WorkerConfig config) async {
    try {
      _isolate = await Isolate.spawn(_entryPoint, config);

      _receivePort!.listen((message) {
        if (message is List<FileNode>) {
          // 转发数据
          _resultController?.add(message);
        }
        else if (message == 'DONE') {
          // 2. 状态流转 -> Done
          // 先关闭数据流
          _resultController?.close();
          // 释放 Isolate 资源 (不设为 Idle)
          _releaseResources();
          // 更新状态为 Done
          _updateState(WorkerState.done);
        }
        else if (message is String && message.startsWith('ERROR:')) {
          // 3. 状态流转 -> Error
          _resultController?.addError(Exception(message));
          _resultController?.close();
          _releaseResources();
          _updateState(WorkerState.error);
        }
      });
    } catch (e) {
      _resultController?.addError(e);
      _releaseResources();
      _updateState(WorkerState.error);
    }
  }


  static void _entryPoint(_WorkerConfig config) async {
    final buffer = <FileNode>[];
    int lastSendTime = DateTime.now().millisecondsSinceEpoch;

    // 配置：缓冲阈值
    const int batchSize = 100; // 每攒够 100 个发一次
    const int flushInterval = 200; // 或者每 200ms 发一次

    // 内部函数：发送并清空缓冲区
    void flush() {
      if (buffer.isNotEmpty) {
        // Isolate 之间的 SendPort.send 会自动处理数据拷贝
        config.sendPort.send(List<FileNode>.from(buffer));
        buffer.clear();
        lastSendTime = DateTime.now().millisecondsSinceEpoch;
      }
    }

    final dir = Directory(config.rootPath);
    if (!await dir.exists()) {
      config.sendPort.send('DONE');
      return;
    }

    try {
      // 遍历文件系统
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {

          // --- 1. 处理普通文件 ---
          final node = _processFile(entity.path, config);
          if (node != null) {
            buffer.add(node);
          }
          // --- 2. 处理压缩包 ---
          else if (config.scanArchives && ArchiveService.isArchive(entity.path)) {
            try {
              final entries = ArchiveService.scanZip(entity, allowedExts: config.extensions);
              for (var entry in entries) {
                final node = _processFile(entry.virtualPath, config);
                if(node != null) buffer.add(node);
              }
            } catch (e) {
              // 忽略错误，继续扫描下一个文件
            }
          }

          //检查缓冲区刷新
          final now = DateTime.now().millisecondsSinceEpoch;
          if (buffer.length >= batchSize || (now - lastSendTime > flushInterval)) {
            flush();
          }
        }
      }

      // 循环结束，发送最后的数据
      flush();
      config.sendPort.send('DONE');
    } catch (e) {
      config.sendPort.send("ERROR: $e");
    } finally {
      Isolate.exit();
    }
  }

  static FileNode? _processFile(String filePath, _WorkerConfig config) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) return null;
    final ext = filePath.substring(lastDotIndex).toLowerCase();
    if (config.extensions.contains(ext)) {
      return FileNode(
        mediaStreamUrl: filePath,
        mediaDownloadUrl: filePath,
        type: _mapModeToType(config.scanMode),
        title: filePath.replaceAll('\\', '/').split('/').last,
      );
    }
    return null;
  }

  static NodeType _mapModeToType(ScanMode mode) {
    switch (mode) {
      case ScanMode.video: return NodeType.video;
      case ScanMode.audio: return NodeType.audio;
      case ScanMode.subtitles: return NodeType.text;
    }
  }
}