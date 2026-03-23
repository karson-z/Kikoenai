import 'package:audio_service/audio_service.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'audio_service_ctrl.dart';
import 'audio_service_media_kit.dart';

extension KikoenaiAudioHandlerX on AudioHandler {

  /// 1. 获取视频渲染控制器
  /// 将烦人的类型强转收敛到这里，UI 层直接调用即可
  VideoController get videoController {
    if (this is MyAudioHandler) {
      return (this as MyAudioHandler).videoController;
    }
    throw UnsupportedError('当前的 AudioHandler 不支持视频渲染配置');
  }

  /// 2. 动态切换视频解码状态（无缝切换音视频流）
  Future<void> toggleVideoDecoding(bool enable) async {
    await customAction('toggleVideoDecoding', {'enable': enable});
  }

  /// 3. 设置是否忽略系统音频焦点
  Future<void> setIgnoreAudioFocus(bool ignore) async {
    await customAction('setIgnoreAudioFocus', {'ignore': ignore});
  }
}

extension MediaItemX on MediaItem {
  /// 判断当前轨道是否为本地文件
  bool get isLocal {
    // 1. 优先检查 id (通常是 URL 或 路径)
    if (extras?['url'].startsWith('/') || extras?['url'].startsWith('file://')) return true;

    // 2. 排除明确的网络协议
    if (extras?['url'].startsWith('http://') || extras?['url'].startsWith('https://')) return false;

    // 3. 兜底检查：如果 id 不含协议头且包含路径分隔符，通常也是本地路径
    return extras?['url'].contains('/');
  }
}