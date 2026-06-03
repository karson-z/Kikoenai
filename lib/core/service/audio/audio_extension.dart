import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';

import '../../../features/album/data/model/work.dart';

extension KikoenaiAudioHandlerX on AudioHandler {
  /// 2. 动态切换视频解码状态（无缝切换音视频流）
  // Future<void> toggleVideoDecoding(bool enable) async {
  //   await customAction('toggleVideoDecoding', {'enable': enable});
  // }

  /// 3. 设置是否忽略系统音频焦点
  Future<void> setIgnoreAudioFocus(bool ignore) async {
    await customAction('setIgnoreAudioFocus', {'ignore': ignore});
  }
}

extension MediaItemX on MediaItem {
  String? get url => extras?['url'] as String?;

  int? get workId {
    final raw = extras?['workId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  NodeSource? get nodeSource {
    final raw = extras?['source'] as String?;
    if (raw == null) return null;
    for (final source in NodeSource.values) {
      if (source.name == raw) return source;
    }
    return null;
  }

  /// 判断当前轨道是否为本地文件
  bool get isLocal {
    final source = nodeSource;
    if (source == NodeSource.localWork || source == NodeSource.localSingle) {
      return true;
    }
    final playbackUrl = url;
    if (playbackUrl == null || playbackUrl.isEmpty) return false;
    // 1. 优先检查 id (通常是 URL 或 路径)
    if (playbackUrl.startsWith('/') || playbackUrl.startsWith('file://')) {
      return true;
    }

    // 2. 排除明确的网络协议
    if (playbackUrl.startsWith('http://') ||
        playbackUrl.startsWith('https://')) {
      return false;
    }

    // 3. 兜底检查：如果 id 不含协议头且包含路径分隔符，通常也是本地路径
    return playbackUrl.contains('/');
  }

  Work? get workData {
    final raw = extras?['workData'];
    if (raw == null) {
      final id = workId;
      return id == null ? null : ScraperStorage().getWork(id);
    }

    try {
      final json = raw is String ? jsonDecode(raw) : raw;
      return Work.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
