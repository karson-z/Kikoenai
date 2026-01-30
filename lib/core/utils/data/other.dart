import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../../features/album/data/model/va.dart';
import '../../../features/album/data/model/work.dart';
import '../../model/search_tag.dart';

/// 工具类，提供与 VA（声优）、页面路由和 MediaItem 相关的常用方法
class OtherUtil {

  static const String sysMarked = '__SYS_PLAYLIST_MARKED';
  static const String sysLiked = '__SYS_PLAYLIST_LIKED';
  /// 将 [VA] 列表中的 name 字段拼接为一个字符串，用 '/' 分隔
  /// - 会过滤掉 name 为 null 或空字符串的项
  /// - 如果 [vas] 为 null 或空列表，则返回空字符串
  /// 示例：
  /// ```dart
  /// final vas = [VA(name: 'A'), VA(name: null), VA(name: 'B')];
  /// final result = OtherUtil.joinVAs(vas); // "A/B"
  /// ```
  static String joinVAs(List<VA>? vas) {
    if (vas == null || vas.isEmpty) return '';
    final names = vas
        .where((va) => va.name != null && va.name!.isNotEmpty)
        .map((va) => va.name!.trim());
    return names.join('/');
  }

  /// 判断给定 [location] 是否属于全屏页面
  /// - 例如播放器页面可能是全屏展示，不显示底部导航栏
  /// - 可以在 Scaffold 或导航逻辑中使用
  /// 示例：
  /// ```dart
  /// final isFullScreen = OtherUtil.isFullScreenPage('/album/detail'); // true
  /// ```
  static bool isFullScreenPage(String location) {
    const fullScreenRoutes = [
      '/detail',
      '/settingsTheme',
    ];
    return fullScreenRoutes.contains(location);
  }

  /// 将 [MediaItem] 转换为 Map，用于存储或序列化为 JSON
  /// - duration 会转换为毫秒数
  /// - extras 会保持 Map<String, dynamic> 形式
  /// 示例：
  /// ```dart
  /// final map = OtherUtil.mediaItemToMap(mediaItem);
  /// ```
  static Map<String, dynamic> mediaItemToMap(MediaItem item) {
    return {
      'id': item.id,
      'album': item.album,
      'title': item.title,
      'artist': item.artist,
      'duration': item.duration?.inMilliseconds,
      'extras': item.extras,
    };
  }

  /// 将 Map 反序列化为 [MediaItem]
  /// - [duration] 以毫秒恢复为 Duration 对象
  /// - [extras] 会被转换为 Map<String, dynamic>
  /// 示例：
  /// ```dart
  /// final mediaItem = OtherUtil.mediaItemFromMap(map);
  /// ```
  static MediaItem mediaItemFromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] ?? '',
      album: map['album'],
      title: map['title'] ?? '',
      artist: map['artist'],
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'])
          : null,
      extras: map['extras'] != null
          ? Map<String, dynamic>.from(map['extras'])
          : null,
    );
  }
  /// 安全解析Work
  // 通用的安全解析
  static List<Work> parseWorks(dynamic value) {
    if (value is List) {
      return value.map((e) {
        try {
          return Work.fromJson(e);
        } catch (ex) {
          print('解析Work失败: $ex');
          print('数据: $e');
          return null;
        }
      }).whereType<Work>().toList();
    }
    return [];
  }
 static Map<String, dynamic> deepConvert(Map input) {
    return input.map((key, value) {
      final newKey = key.toString();

      if (value is Map) {
        return MapEntry(newKey, deepConvert(value));
      } else if (value is List) {
        return MapEntry(newKey, value.map((e) {
          if (e is Map) {
            return deepConvert(e);
          }
          return e;
        }).toList());
      } else {
        return MapEntry(newKey, value);
      }
    });
  }
  /// 格式化字节数为人类可读的字符串
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }


  static bool needUpdate(localVersion, remoteVersion) {
    List<String> localVersionList = localVersion.split('.');
    List<String> remoteVersionList = remoteVersion.split('.');
    for (int i = 0; i < localVersionList.length; i++) {
      int localVersion = int.parse(localVersionList[i]);
      int remoteVersion = int.parse(remoteVersionList[i]);
      if (remoteVersion > localVersion) {
        return true;
      } else if (remoteVersion < localVersion) {
        return false;
      }
    }
    return false;
  }

  static Future<String> calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }


  /// 核心转换逻辑
  static String getDisplayName(String? rawName) {
    if (rawName == null) return '';

    switch (rawName) {
      case sysMarked:
        return '我的标记'; // 对应稍后观看/标记
      case sysLiked:
        return '我喜欢的';
      default:
        return rawName;
    }
  }
  // 拿到不同类型文件的图标
  static IconData getFileIcon(String ext) {
    if (['MP3', 'WAV', 'FLAC', 'M4A'].contains(ext)) return Icons.audiotrack;
    if (['JPG', 'PNG', 'GIF'].contains(ext)) return Icons.image;
    if (['TXT', 'LRC'].contains(ext)) return Icons.description;
    return Icons.insert_drive_file;
  }
}