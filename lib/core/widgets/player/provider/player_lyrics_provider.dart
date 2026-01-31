import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';

import '../../../model/lyric_model.dart';
import '../../../service/file/archive_service.dart';
import '../../../service/lyrics/lyrics_parse_service.dart';

// 定义 Provider
final lyricsProvider = AsyncNotifierProvider<LyricsNotifier, List<LyricsLineModel>>(
      () => LyricsNotifier(),
);

class LyricsNotifier extends AsyncNotifier<List<LyricsLineModel>> {
  // 新增：用于记录当前 state 中对应的是哪个 URL 的歌词
  String? _loadedUrl;

  @override
  Future<List<LyricsLineModel>> build() async {
    return [];
  }

  String? get currentLoadedUrl => _loadedUrl;

  Future<void> loadLyrics() async {
    final playerState = ref.read(playerControllerProvider);
    final currentSub = playerState.currentSubtitle;
    final newUrl = currentSub?.mediaStreamUrl;

    // 1. 基础判断
    if (newUrl == null || newUrl.isEmpty) {
      if (_loadedUrl != null) {
        _loadedUrl = null;
        state = const AsyncValue.data([]);
      }
      return;
    }

    // 2. 缓存判断
    if (newUrl == _loadedUrl && state.hasValue && !state.isLoading) {
      return;
    }

    _loadedUrl = newUrl;
    state = const AsyncValue.loading();

    try {
      final format = LyricsParserFactory.guessFormat(currentSub?.title ?? '');
      String content;

      // 3. [修改] 区分 远程 / 本地普通文件 / 压缩包文件
      if (newUrl.startsWith('http') || newUrl.startsWith('https')) {
        // A. 远程网络加载
        final api = ref.read(apiClientProvider);
        final response = await api.get(newUrl);
        content = response.data.toString();
      } else {
        // B. 本地加载逻辑
        final file = File(newUrl);

        if (await file.exists()) {
          // B1. 是普通存在的本地文件 (例如已经解压出来的，或者外挂字幕)
          content = await file.readAsString();
        } else {
          // B2.  尝试从压缩包读取
          final zipContent = await ArchiveService.extractText(newUrl);

          if (zipContent != null) {
            content = zipContent;
          } else {
            throw Exception("本地字幕不存在，且无法从压缩包提取: $newUrl");
          }
        }
      }

      // 4. 解析逻辑（保持不变）
      final lines = await compute(
        _parseLyricsInIsolate,
        _ParseParams(content, format),
      );

      // 5. 竞态检查
      if (_loadedUrl != newUrl) {
        debugPrint("加载期间发生了切歌，丢弃本次结果");
        return;
      }

      state = AsyncValue.data(lines);
    } catch (e, st) {
      if (_loadedUrl == newUrl) {
        debugPrint('歌词加载/解析失败: $e');
        state = AsyncValue.error(e, st);
      }
    }
  }

  void clear() {
    _loadedUrl = null;
    state = const AsyncValue.data([]);
  }
}
class _ParseParams {
  final String content;
  final LyricFormat format;

  _ParseParams(this.content, this.format);
}

/// 这是一个纯函数，运行在单独的 Isolate 中
Future<List<LyricsLineModel>> _parseLyricsInIsolate(_ParseParams params) async {
  final parser = LyricsParserFactory.create(
    params.content,
    params.format,
  );
  return parser.parseLines(isMain: true);
}
final currentLyricIndexProvider = Provider<int>((ref) {
  // 1. 监听播放进度
  final currentPositionMs = ref.watch(
    playerControllerProvider.select((s) => s.progressBarState.current.inMilliseconds),
  );

  // 2. 监听歌词列表
  final lyricsState = ref.watch(lyricsProvider);

  // 3. 计算索引
  return lyricsState.maybeWhen(
    data: (lyrics) {
      return lyrics.getCurrentLine(currentPositionMs);
    },
    // 如果是 loading, error 或数据为空，默认返回第 0 行
    orElse: () => 0,
  );
});

// 状态：bool (true = 正在拖拽/暂停自动滚动, false = 自动滚动模式)
final lyricScrollStateProvider = NotifierProvider.autoDispose<LyricScrollNotifier, bool>(
  LyricScrollNotifier.new,
);

class LyricScrollNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false; // false = 自动滚动模式, true = 拖拽中
  }

  void startDragging() {
    debugPrint("⏰ 开始拖拽，停止自动滚动");
    _timer?.cancel();
    state = true;
  }

  /// 用户停止拖拽，开始倒计时恢复
  void stopDragging() {
    _timer?.cancel();
    // 3秒后将状态重置为 false
    _timer = Timer(const Duration(seconds: 3), () {
      state = false;
      debugPrint("⏰ 3秒倒计时结束，准备恢复自动滚动");
    });
  }
}