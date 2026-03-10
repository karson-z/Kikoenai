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

  /// 【核心新增】：辅助方法，从路径中逆向提取 RJ 号
  /// 逆向提取的好处是：如果文件叫 sub.srt，它会去找父文件夹名；如果文件本身叫 RJ123456.srt，就直接提取
  static String? _extractRjCodeFromPath(String path) {
    final segments = path.split('/');
    // 倒序遍历，优先获取最贴近文件的 RJ 号
    for (int i = segments.length - 1; i >= 0; i--) {
      final match = _rjRegex.firstMatch(segments[i]);
      if (match != null) {
        return match.group(0)!.toUpperCase();
      }
    }
    return null;
  }

  static void _entryPoint(_WorkerConfig config) async {
    final buffer = <FileNode>[];

    final pendingDirectories = <String, FileNode>{};
    final emittedDirectories = <String>{};
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

    String getDirname(String path) {
      final lastSlash = path.lastIndexOf('/');
      return lastSlash > 0 ? path.substring(0, lastSlash) : path;
    }

    void flushAncestors(String filePath) {
      String current = getDirname(filePath);
      while (true) {
        if (emittedDirectories.contains(current)) break;

        if (pendingDirectories.containsKey(current)) {
          buffer.add(pendingDirectories.remove(current)!);
          emittedDirectories.add(current);
        }

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

        if (entity is Directory) {
          final node = _processDirectory(entity, config);
          if (node != null) {
            pendingDirectories[node.mediaStreamUrl!] = node;
          }
        }
        else if (entity is File) {
          final node = _processFile(entity, config);
          if (node != null) {
            buffer.add(node);
            flushAncestors(node.mediaStreamUrl!);
          }
          else if (config.scanArchives && ArchiveService.isArchive(entity.path)) {
            try {
              int archiveLastMod = 0;
              try { archiveLastMod = entity.statSync().modified.millisecondsSinceEpoch; } catch(_) {}

              final entries = ArchiveService.scanZip(entity, allowedExts: config.extensions);
              bool hasValidArchiveEntry = false;

              for (var entry in entries) {
                // 【核心修改】：把压缩包本身的路径 entity.path 也传进去，用于匹配 RJ 号
                final zipNode = _processArchiveEntry(entity.path, entry.virtualPath, archiveLastMod, config);
                if(zipNode != null) {
                  buffer.add(zipNode);
                  hasValidArchiveEntry = true;
                }
              }

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

    } catch (e) {
      config.sendPort.send("ERROR: $e");
    } finally {
      Isolate.exit();
    }
  }

  /// 【核心修改】：接收压缩包本体路径 `archivePath`，从而能从压缩包的名字中提取 RJ 号
  static FileNode? _processArchiveEntry(String archivePath, String virtualPath, int lastMod, _WorkerConfig config) {
    final lastDotIndex = virtualPath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == virtualPath.length - 1) return null;
    final ext = virtualPath.substring(lastDotIndex).toLowerCase();

    if (config.extensions.contains(ext)) {
      final normalizedVirtualPath = virtualPath.replaceAll('\\', '/');
      final normalizedArchivePath = archivePath.replaceAll('\\', '/');

      String? rjCode;
      // 在字幕模式下，拼接压缩包路径和虚拟路径，从中提取 RJ 号
      if (config.scanMode == ScanMode.subtitles) {
        rjCode = _extractRjCodeFromPath('$normalizedArchivePath/$normalizedVirtualPath');
      }

      return FileNode(
        mediaStreamUrl: normalizedVirtualPath,
        mediaDownloadUrl: normalizedVirtualPath,
        type: _mapModeToType(config.scanMode),
        title: normalizedVirtualPath.split('/').last,
        lastModified: lastMod,
        nodeStatus: NodeStatus.normal,
        rjCode: rjCode,
      );
    }
    return null;
  }

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

    int lastMod = 0;
    try { lastMod = dir.statSync().modified.millisecondsSinceEpoch; } catch(_) {}

    return FileNode(
      mediaStreamUrl: normalizedPath,
      type: NodeType.folder,
      title: currentDirName,
      nodeStatus: status,
      rjCode: rjCode,
      lastModified: lastMod,
    );
  }

  static FileNode? _processFile(File file, _WorkerConfig config) {
    final filePath = file.path;
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) return null;
    final ext = filePath.substring(lastDotIndex).toLowerCase();

    if (config.extensions.contains(ext)) {
      final normalizedPath = filePath.replaceAll('\\', '/');

      int lastMod = 0;
      try { lastMod = file.statSync().modified.millisecondsSinceEpoch; } catch(_) {}

      String? rjCode;
      // 在字幕模式下，从当前文件的全路径中尝试提取 RJ 号
      if (config.scanMode == ScanMode.subtitles) {
        rjCode = _extractRjCodeFromPath(normalizedPath);
      }

      return FileNode(
        mediaStreamUrl: normalizedPath,
        mediaDownloadUrl: normalizedPath,
        type: _mapModeToType(config.scanMode),
        title: normalizedPath.split('/').last,
        lastModified: lastMod,
        // 【核心修改】：强制普通状态，并注入可能存在的 RJ 号
        nodeStatus: NodeStatus.normal,
        rjCode: rjCode,
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