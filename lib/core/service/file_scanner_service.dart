// core/service/file_scanner_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_file_extensions.dart';
import '../model/app_media_item.dart';

enum ScanMode { audio, video }

class IsolateInitParams {
  final SendPort sendPort;
  final String rootPath;
  final Set<String> allowExts;
  final ScanMode mode;

  IsolateInitParams({
    required this.sendPort,
    required this.rootPath,
    required this.allowExts,
    required this.mode,
  });
}

class ScannerService {

  /// 如果文件有效且符合当前模式，返回 AppMediaItem，否则返回 null
  static Future<AppMediaItem?> parseFile(File file, {required ScanMode mode}) async {
    // 1. 基础检查
    if (!file.existsSync()) return null;
    final path = file.path;
    if (!path.contains('.')) return null;
    // 2. 检查后缀名
    final ext = path.substring(path.lastIndexOf('.')).toLowerCase();
    final validExts = mode == ScanMode.audio ? FileExtensions.audio : FileExtensions.video;

    // 假设 FileExtensions.audio 是 Set<String>
    if (!validExts.contains(ext)) return null;

    // 3. 根据模式解析
    try {
      if (mode == ScanMode.audio) {
        return _parseAudio(file);
      } else {
        return _parseVideo(file);
      }
    } catch (e) {
      debugPrint("ScannerService: 单文件解析失败 $path, $e");
      return null;
    }
  }

  /// 扫描音频流 (批量)
  static Stream<List<AppMediaItem>> scanAudioStream(String directoryPath) {
    return _createStream(directoryPath, ScanMode.audio);
  }

  /// 扫描视频流 (批量)
  static Stream<List<AppMediaItem>> scanVideoStream(String directoryPath) {
    return _createStream(directoryPath, ScanMode.video);
  }

  /// 内部通用流构建方法
  static Stream<List<AppMediaItem>> _createStream(String directoryPath, ScanMode mode) {
    late StreamController<List<AppMediaItem>> controller;
    Isolate? isolate;
    ReceivePort? receivePort;

    controller = StreamController<List<AppMediaItem>>(
      onListen: () async {
        receivePort = ReceivePort();

        final params = IsolateInitParams(
          sendPort: receivePort!.sendPort,
          rootPath: directoryPath,
          allowExts: mode == ScanMode.audio ? FileExtensions.audio : FileExtensions.video,
          mode: mode,
        );

        try {
          isolate = await Isolate.spawn(_isolateEntry, params);
        } catch (e) {
          controller.addError(e);
          controller.close();
          return;
        }

        receivePort!.listen((message) {
          if (message is List<AppMediaItem>) {
            controller.add(message);
          } else if (message == 'DONE') {
            controller.close();
            receivePort?.close();
            isolate?.kill();
          }
        });
      },
      onCancel: () {
        receivePort?.close();
        isolate?.kill(priority: Isolate.immediate);
      },
    );

    return controller.stream;
  }

  // --- 后台 Isolate 入口 ---
  static void _isolateEntry(IsolateInitParams params) {
    final dir = Directory(params.rootPath);
    List<AppMediaItem> buffer = [];
    const int batchSize = 10;

    // 为了性能，在循环外转换一次
    final validExts = params.allowExts.map((e) => e.toLowerCase()).toSet();

    try {
      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: true);

        for (var entity in entities) {
          if (entity is File) {
            final path = entity.path;
            if (!path.contains('.')) continue;

            final ext = path.substring(path.lastIndexOf('.')).toLowerCase();

            if (validExts.contains(ext)) {
              final item = params.mode == ScanMode.audio
                  ? _parseAudio(entity)
                  : _parseVideo(entity);

              buffer.add(item);

              if (buffer.length >= batchSize) {
                params.sendPort.send(List<AppMediaItem>.from(buffer));
                buffer.clear();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("ScannerService: 后台扫描错误: $e");
    } finally {
      if (buffer.isNotEmpty) {
        params.sendPort.send(buffer);
      }
      params.sendPort.send('DONE');
    }
  }

  // --- 解析策略 (抽取为静态方法供 Isolate 和 parseFile 共用) ---

  // 策略 A: 音频
  static AppMediaItem _parseAudio(File file) {
    final fileName = file.uri.pathSegments.last;
    try {
      final metadata = readMetadata(file);

      // --- 新增：提取封面图片逻辑 ---
      Uint8List? coverBytes;
      if (metadata.pictures.isNotEmpty) {
        // 通常取第一张作为封面
        coverBytes = metadata.pictures.first.bytes;
      }

      return AppMediaItem(
        path: file.path,
        fileName: fileName,
        title: metadata.title ?? fileName,
        artist: metadata.artist ?? "未知歌手",
        album: metadata.album ?? "未知专辑",
        durationSeconds: metadata.duration?.inSeconds.toDouble() ?? 0.0,
        coverBytes: coverBytes, // 传入图片数据
      );
    } catch (e) {
      return AppMediaItem(
        path: file.path,
        fileName: fileName,
        title: fileName,
        artist: "未知",
        album: "未知",
        durationSeconds: 0,
        coverBytes: null,
      );
    }
  }

  // 策略 B: 视频
  static AppMediaItem _parseVideo(File file) {
    final fileName = file.uri.pathSegments.last;
    // 注意：视频提取缩略图通常非常耗时，且 audio_metadata_reader 可能不支持视频
    // 如果需要视频缩略图，建议在 UI 层懒加载，或者使用专门的 video_thumbnail 库
    return AppMediaItem(
      path: file.path,
      fileName: fileName,
      title: fileName,
      artist: "本地视频",
      album: "视频",
      durationSeconds: 0,
      coverBytes: null, // 视频暂不扫描封面，防止卡顿
    );
  }
}