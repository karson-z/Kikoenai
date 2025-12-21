import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_file_extensions.dart';
import '../model/app_media_item.dart';
import 'archive_service.dart';

enum ScanMode { audio, video, subtitles }

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

  /// 辅助方法：根据模式获取对应的合法扩展名集合
  static Set<String> _getValidExts(ScanMode mode) {
    switch (mode) {
      case ScanMode.audio:
        return FileExtensions.audio;
      case ScanMode.video:
        return FileExtensions.video;
      case ScanMode.subtitles:
      // 假设 FileExtensions.subtitles 是类似于 {'.srt', '.ass', '.vtt', '.lrc'} 的集合
        return FileExtensions.subtitles;
    }
  }

  /// 如果文件有效且符合当前模式，返回 AppMediaItem，否则返回 null
  static Future<AppMediaItem?> parseFile(File file, {required ScanMode mode}) async {
    // 1. 基础检查
    if (!file.existsSync()) return null;
    final path = file.path;
    if (!path.contains('.')) return null;

    // 2. 检查后缀名 (使用辅助方法获取扩展名列表)
    final ext = path.substring(path.lastIndexOf('.')).toLowerCase();
    final validExts = _getValidExts(mode);

    if (!validExts.contains(ext)) return null;

    // 3. 根据模式解析
    try {
      switch (mode) {
        case ScanMode.audio:
          return _parseAudio(file);
        case ScanMode.video:
          return _parseVideo(file);
        case ScanMode.subtitles: // [新增] 字幕解析入口
          return _parseSubtitle(file);
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

  /// [新增] 扫描字幕流 (批量)
  static Stream<List<AppMediaItem>> scanSubtitleStream(String directoryPath) {
    return _createStream(directoryPath, ScanMode.subtitles);
  }

  /// 内部通用流构建方法
  static Stream<List<AppMediaItem>> _createStream(String directoryPath, ScanMode mode) {
    late StreamController<List<AppMediaItem>> controller;
    Isolate? isolate;
    ReceivePort? receivePort;

    controller = StreamController<List<AppMediaItem>>(
      onListen: () async {
        receivePort = ReceivePort();

        // 使用 _getValidExts 统一获取扩展名
        final params = IsolateInitParams(
          sendPort: receivePort!.sendPort,
          rootPath: directoryPath,
          allowExts: _getValidExts(mode),
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

    final validExts = params.allowExts.map((e) => e.toLowerCase()).toSet();
    final bool scanArchives = params.mode == ScanMode.subtitles;

    try {
      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: true);

        for (var entity in entities) {
          if (entity is File) {
            final path = entity.path;
            // 简单检查是否有扩展名
            if (!path.contains('.')) continue;

            final ext = path.substring(path.lastIndexOf('.')).toLowerCase();

            // 1. 普通文件处理
            if (validExts.contains(ext)) {
              final item = _parseItemByMode(entity, params.mode);
              buffer.add(item);
            }
            // 2. [修改] 压缩包文件处理 (使用 ArchiveService)
            else if (scanArchives && ArchiveService.isArchive(path)) {
              // 调用服务扫描
              final entries = ArchiveService.scanZip(entity, allowedExts: validExts);

              for (var entry in entries) {
                buffer.add(AppMediaItem(
                  path: entry.virtualPath, // 现在是 /path/to.zip/sub.srt
                  fileName: entry.name,
                  title: entry.name,
                  artist: "压缩包字幕",
                  album: entity.uri.pathSegments.last,
                  durationSeconds: 0,
                  coverBytes: null,
                ));
              }
            }
            // 发送缓冲
            if (buffer.length >= batchSize) {
              params.sendPort.send(List<AppMediaItem>.from(buffer));
              buffer.clear();
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
  static AppMediaItem _parseItemByMode(File file, ScanMode mode) {
    switch (mode) {
      case ScanMode.audio:
        return _parseAudio(file);
      case ScanMode.video:
        return _parseVideo(file);
      case ScanMode.subtitles:
        return _parseSubtitle(file);
    }
  }

  // 策略 A: 音频
  static AppMediaItem _parseAudio(File file) {
    final fileName = file.uri.pathSegments.last;
    try {
      final metadata = readMetadata(file);
      Uint8List? coverBytes;
      if (metadata.pictures.isNotEmpty) {
        coverBytes = metadata.pictures.first.bytes;
      }

      return AppMediaItem(
        path: file.path,
        fileName: fileName,
        title: metadata.title ?? fileName,
        artist: metadata.artist ?? "未知歌手",
        album: metadata.album ?? "未知专辑",
        durationSeconds: metadata.duration?.inSeconds.toDouble() ?? 0.0,
        coverBytes: coverBytes,
      );
    } catch (e) {
      // 降级处理
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
    return AppMediaItem(
      path: file.path,
      fileName: fileName,
      title: fileName,
      artist: "本地视频",
      album: "视频",
      durationSeconds: 0,
      coverBytes: null,
    );
  }

  // 策略 C: 字幕 [新增]
  static AppMediaItem _parseSubtitle(File file) {
    final fileName = file.uri.pathSegments.last;
    // 字幕文件通常没有内嵌元数据，我们主要关心文件名和路径
    // 如果文件名类似于 "MovieName.chs.srt"，UI层可能需要处理一下展示逻辑
    return AppMediaItem(
      path: file.path,
      fileName: fileName,
      title: fileName, // 字幕通常直接用文件名作为标题
      artist: "字幕文件",  // 占位符
      album: "External Subtitle", // 占位符
      durationSeconds: 0,
      coverBytes: null,
    );
  }
}