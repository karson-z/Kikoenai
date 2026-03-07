import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'archive_service.dart';
import 'file_scanner_service.dart';

enum WorkerState {
  idle,
  scanning,
  done,
  error,
}

/// 传递给 Isolate 的配置参数 (DTO)
class _WorkerConfig {
  final String rootPath;
  final Set<String> extensions;
  final bool scanArchives;
  final ScanMode scanMode;
  final SendPort sendPort;
  final Set<String> parsedRjCodes;

  _WorkerConfig({
    required this.rootPath,
    required this.extensions,
    required this.scanArchives,
    required this.scanMode,
    required this.sendPort,
    required this.parsedRjCodes,
  });
}

class FileScanWorker {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  StreamController<List<FileNode>>? _resultController;

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
    required Set<String> parsedRjCodes,
  }) {
    _releaseResources();
    _updateState(WorkerState.scanning);

    _resultController = StreamController<List<FileNode>>();
    _receivePort = ReceivePort();

    final config = _WorkerConfig(
      rootPath: path,
      extensions: extensions,
      scanArchives: scanArchives,
      scanMode: scanMode,
      sendPort: _receivePort!.sendPort,
      parsedRjCodes: parsedRjCodes,
    );

    _spawnIsolate(config);
    return _resultController!.stream;
  }

  void dispose() {
    _releaseResources();
    _updateState(WorkerState.idle);
  }

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
          _resultController?.add(message);
        } else if (message == 'DONE') {
          _resultController?.close();
          _releaseResources();
          _updateState(WorkerState.done);
        } else if (message is String && message.startsWith('ERROR:')) {
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

  // ==================== Isolate 内部逻辑 ====================

  // 预编译正则：匹配 RJ 或 RJ0 开头，后接 6-8 位数字
  static final RegExp _rjRegex = RegExp(r'RJ0?\d{6,8}', caseSensitive: false);

  static void _entryPoint(_WorkerConfig config) async {
    final buffer = <FileNode>[];

    // 【核心新增】：延迟发射机制的暂存区
    final pendingDirectories = <String, FileNode>{};
    final emittedDirectories = <String>{}; // 记录已经发送过的文件夹，避免重复发送
    final rootPathNorm = config.rootPath.replaceAll('\\', '/');

    int lastSendTime = DateTime.now().millisecondsSinceEpoch;
    const int batchSize = 100;
    const int flushInterval = 200;

    void flush() {
      if (buffer.isNotEmpty) {
        config.sendPort.send(List<FileNode>.from(buffer));
        buffer.clear();
        lastSendTime = DateTime.now().millisecondsSinceEpoch;
      }
    }

    // 辅助方法：快速获取父路径
    String getDirname(String path) {
      final lastSlash = path.lastIndexOf('/');
      return lastSlash > 0 ? path.substring(0, lastSlash) : path;
    }

    // 【核心新增】：顺藤摸瓜，将合法文件的父目录从暂存区激活并发送
    void flushAncestors(String filePath) {
      String current = getDirname(filePath);
      while (true) {
        // 如果这个父目录已经发射过了，说明再往上的祖先肯定也发射过了，直接停止
        if (emittedDirectories.contains(current)) break;

        // 如果在待定区里，把它拿出来放进发送缓冲，并标记为已发射
        if (pendingDirectories.containsKey(current)) {
          buffer.add(pendingDirectories.remove(current)!);
          emittedDirectories.add(current);
        }

        // 已经追溯到了根目录，或者到顶了，停止循环
        if (current == rootPathNorm || current == getDirname(current)) break;
        current = getDirname(current);
      }
    }

    final dir = Directory(config.rootPath);
    if (!await dir.exists()) {
      config.sendPort.send('DONE');
      return;
    }

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {

        // --- 1. 处理文件夹：盖章并放入【暂存区】 ---
        if (entity is Directory) {
          final node = _processDirectory(entity, config);
          if (node != null) {
            // 存入暂存区，键为标准化后的绝对路径
            pendingDirectories[node.mediaStreamUrl!] = node;
          }
        }
        // --- 2. 处理普通文件 ---
        else if (entity is File) {
          final node = _processFile(entity, config);
          if (node != null) {
            buffer.add(node);
            // 既然文件有效，立即激活它所有的父目录！
            flushAncestors(node.mediaStreamUrl!);
          }

          // --- 3. 处理压缩包 ---
          else if (config.scanArchives && ArchiveService.isArchive(entity.path)) {
            try {
              int archiveLastMod = 0;
              try { archiveLastMod = entity.statSync().modified.millisecondsSinceEpoch; } catch(_) {}

              final entries = ArchiveService.scanZip(entity, allowedExts: config.extensions);
              bool hasValidArchiveEntry = false;

              for (var entry in entries) {
                final zipNode = _processArchiveEntry(entry.virtualPath, archiveLastMod, config);
                if(zipNode != null) {
                  buffer.add(zipNode);
                  hasValidArchiveEntry = true;
                }
              }

              // 只要压缩包里有有效文件，就把压缩包所在的父目录激活！
              if (hasValidArchiveEntry) {
                flushAncestors(entity.path.replaceAll('\\', '/'));
              }
            } catch (e) {
              // 忽略错误
            }
          }
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        if (buffer.length >= batchSize || (now - lastSendTime > flushInterval)) {
          flush();
        }
      }

      flush();
      config.sendPort.send('DONE');

      // 注意：循环结束后，留在 pendingDirectories 里的文件夹，
      // 就是那些没有匹配文件的“空壳”文件夹。随着 Isolate 的销毁，它们会被自动无情抹除！

    } catch (e) {
      config.sendPort.send("ERROR: $e");
    } finally {
      Isolate.exit();
    }
  }
  static FileNode? _processArchiveEntry(String virtualPath, int lastMod, _WorkerConfig config) {
    final lastDotIndex = virtualPath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == virtualPath.length - 1) return null;
    final ext = virtualPath.substring(lastDotIndex).toLowerCase();

    if (config.extensions.contains(ext)) {
      final normalizedPath = virtualPath.replaceAll('\\', '/');

      return FileNode(
        mediaStreamUrl: normalizedPath,
        mediaDownloadUrl: normalizedPath,
        type: _mapModeToType(config.scanMode),
        title: normalizedPath.split('/').last,
        lastModified: lastMod,
      );
    }
    return null;
  }
  /// 鉴定文件夹：执行正则与查表，组装完整状态的 Folder Node
  static FileNode? _processDirectory(Directory dir, _WorkerConfig config) {
    final normalizedPath = dir.path.replaceAll('\\', '/');
    final segments = normalizedPath.split('/');
    final currentDirName = segments.last;

    NodeStatus status = NodeStatus.normal;
    String? rjCode;

    for (final segment in segments) {
      final match = _rjRegex.firstMatch(segment);
      if (match != null) {
        if (segment == currentDirName) {
          rjCode = match.group(0)!.toUpperCase();
          status = config.parsedRjCodes.contains(rjCode)
              ? NodeStatus.parsed
              : NodeStatus.pending;
        }
        break;
      }
    }

    // 获取物理修改时间
    int lastMod = 0;
    try { lastMod = dir.statSync().modified.millisecondsSinceEpoch; } catch(_) {}

    return FileNode(
      mediaStreamUrl: normalizedPath,
      type: NodeType.folder,
      title: currentDirName,
      nodeStatus: status,
      rjCode: rjCode,
      lastModified: lastMod, // 【关键】注入真实时间
    );
  }

  static FileNode? _processFile(File file, _WorkerConfig config) {
    final filePath = file.path;
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) return null;
    final ext = filePath.substring(lastDotIndex).toLowerCase();

    if (config.extensions.contains(ext)) {
      final normalizedPath = filePath.replaceAll('\\', '/');

      // 获取物理修改时间
      int lastMod = 0;
      try { lastMod = file.statSync().modified.millisecondsSinceEpoch; } catch(_) {}

      return FileNode(
        mediaStreamUrl: normalizedPath,
        mediaDownloadUrl: normalizedPath,
        type: _mapModeToType(config.scanMode),
        title: normalizedPath.split('/').last,
        lastModified: lastMod, // 【关键】注入真实时间
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