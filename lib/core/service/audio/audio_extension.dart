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

