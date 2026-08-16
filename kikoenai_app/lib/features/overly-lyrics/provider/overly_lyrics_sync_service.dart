import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_lyric/core/lyric_model.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';

import '../../../../core/service/lyrics/lyrics_parse_service.dart';
import '../../player/provider/player_controller_provider.dart';
import '../../player/provider/player_lyrics_match_provider.dart';
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
  String? _lastBoundUrl;

  StreamSubscription? _positionSub;
  ProviderSubscription? _trackSub; // 监听曲目 id 变化
  ProviderSubscription? _mappingSub; // 监听字幕映射变化
  ProviderSubscription? _contentSub; // 监听 family 字幕内容

  bool _isSyncing = false; // 记录当前是否正在同步

  // 构造函数：不再自动执行 _init()
  OverlayLyricSyncService(this.ref);

  /// 解析当前曲目应使用的字幕 URL（track id → 映射 → URL）
  String? _currentLyricUrl() {
    final currentItemId = ref.read(playerControllerProvider).currentItem?.id;
    if (currentItemId == null) return null;
    final mapping = ref.read(lyricsMatchControllerProvider).subtitleMapping;
    final url = mapping[currentItemId]?.mediaStreamUrl;
    return (url == null || url.isEmpty) ? null : url;
  }

  /// 曲目或映射变化时，重新绑定对 [lyricsContentProvider] family 的监听。
  /// URL 未变化时跳过，避免重复解析。
  void _bindContentListener() {
    final url = _currentLyricUrl();

    if (url == null) {
      _lastBoundUrl = null;
      _contentSub?.close();
      _contentSub = null;
      _handleNoLyrics();
      return;
    }

    if (url == _lastBoundUrl && _contentSub != null) return;
    _lastBoundUrl = url;

    _contentSub?.close();
    _contentSub = ref.listen<AsyncValue<String?>>(
      lyricsContentProvider(url),
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
      fireImmediately: true, // 绑定时如果 family 已有数据，会立刻触发渲染
    );
  }

  /// 开启字幕同步（显示悬浮窗时调用）
  void startSync() {
    if (_isSyncing) return;
    _isSyncing = true;
    _lastSentLyric = '';

    // 曲目变化：重新解析当前字幕 URL
    _trackSub = ref.listen(
      playerControllerProvider.select((s) => s.currentItem?.id),
      (previous, next) {
        if (previous != next) _bindContentListener();
      },
    );
    // 用户手动切换字幕（映射更新）：同样重新绑定
    _mappingSub = ref.listen(
      lyricsMatchControllerProvider.select((s) => s.subtitleMapping),
      (previous, next) => _bindContentListener(),
    );
    _bindContentListener();

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

    // 2. 切断曲目 / 映射 / 内容监听
    _trackSub?.close();
    _trackSub = null;
    _mappingSub?.close();
    _mappingSub = null;
    _contentSub?.close();
    _contentSub = null;
    _lastBoundUrl = null;

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