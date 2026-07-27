import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_lyric/core/lyric_model.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';

import '../../../../core/service/lyrics/lyrics_parse_service.dart';
import '../../player/provider/player_controller_provider.dart';
import '../../player/provider/player_lyrics_provider.dart';
import 'overly_lyrics_provider.dart';

final overlayLyricSyncProvider = Provider<OverlayLyricSyncService>((ref) {
  final service = OverlayLyricSyncService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class OverlayLyricSyncService {
  final Ref ref;

  LyricModel? _currentLyricModel;
  String _lastSentLyric = '';

  StreamSubscription? _positionSub;
  ProviderSubscription? _urlSub;

  bool _isSyncing = false; // 记录当前是否正在同步

  // 构造函数：不再自动执行 _init()
  OverlayLyricSyncService(this.ref);

  /// 开启字幕同步（显示悬浮窗时调用）
  void startSync() {
    if (_isSyncing) return;
    _isSyncing = true;
    _lastSentLyric = '';

    _urlSub = ref.listen<AsyncValue<String?>>(
      lyricsProvider,
          (previous, next) {
        next.when(
          data: (rawLrc) {
            if (rawLrc != null && rawLrc.isNotEmpty) {
              try {
                // 1. 解析歌词
                _currentLyricModel = LyricParse.parse(
                  rawLrc,
                  parsers: [VttParser(), LrcParser(), QrcParser(), FallbackParser()],
                );

                // 2. 立即计算一次当前位置，确保数据第一时间发出
                final currentPosition = ref.read(playerControllerProvider).progressBarState.current;
                _onPositionChanged(currentPosition);

                // 3. 核心修复：数据准备好了，确保窗口打开
                ref.read(lyricsControllerProvider.notifier).show();
              } catch (e) {
                debugPrint('字幕解析异常: $e');
                _handleNoLyrics();
              }
            } else {
              // 数据为空，自动隐藏
              _handleNoLyrics();
            }
          },
          loading: () {
          },
          error: (err, stack) {
            debugPrint('歌词 Provider 错误: $err');
            _handleNoLyrics();
          },
        );
      },
      fireImmediately: true, // 这样开启时如果 Provider 已有数据，会立刻触发渲染
    );

    _positionSub = AudioService.position.listen(_onPositionChanged);
  }
  void _handleNoLyrics() {
    _currentLyricModel = null;
    ref.read(lyricsControllerProvider.notifier).hide();
  }
  /// 关闭字幕同步（隐藏悬浮窗时调用）
  void stopSync() {
    if (!_isSyncing) return;
    _isSyncing = false;

    // 1. 切断高频进度监听
    _positionSub?.cancel();
    _positionSub = null;

    // 2. 切断 URL 变化监听
    _urlSub?.close();
    _urlSub = null;

    // 3. 释放内存
    _currentLyricModel = null;
  }

  void _onPositionChanged(Duration position) {
    if (_currentLyricModel == null || _currentLyricModel!.lines.isEmpty) return;

    final lines = _currentLyricModel!.lines;
    int playIndex = _getIndexByProgress(position, lines);

    final currentLine = lines[playIndex];
    String displayText = currentLine.text;

    if (currentLine.translation != null && currentLine.translation!.isNotEmpty) {
      displayText += '\n${currentLine.translation}';
    }

    if (displayText != _lastSentLyric) {
      _lastSentLyric = displayText;
      _sendToOverlay(displayText);
    }
  }

  int _getIndexByProgress(Duration progress, List<LyricLine> lines) {
    int left = 0;
    int right = lines.length - 1;
    int result = -1;

    while (left <= right) {
      int mid = left + ((right - left) >> 1);
      if (progress == lines[mid].start) {
        return mid;
      } else if (progress < lines[mid].start) {
        right = mid - 1;
      } else {
        result = mid;
        left = mid + 1;
      }
    }
    return result < 0 ? 0 : result;
  }

  void _sendToOverlay(String text) {
    ref.read(subtitleManagerProvider).syncBusinessState({
      'text': text,
    });
  }

  void dispose() {
    stopSync(); // 随 Provider 销毁时安全释放
  }
}