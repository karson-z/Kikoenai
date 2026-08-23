import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_error_retry_view.dart';
import 'package:kikoenai/features/player/widget/lyrics/player_lyrics_widget.dart';

import '../../provider/player_controller_provider.dart';
import '../../provider/player_lyrics_match_provider.dart';
import '../../provider/player_lyrics_provider.dart';

class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  @override
  Widget build(BuildContext context) {
    // 只监听稳定的 track id，避免 currentItem 因 duration 等元数据更新而重建
    final currentItemId = ref.watch(
      playerControllerProvider.select((s) => s.currentItem?.id),
    );
    final subtitleMapping = ref.watch(
      lyricsMatchControllerProvider.select((s) => s.subtitleMapping),
    );
    final lyricUrl = currentItemId == null
        ? null
        : subtitleMapping[currentItemId]?.mediaStreamUrl;

    // 监听当前进度提供给flutter_lyrics 使用
    final progressNotifier = ref.watch(playerControllerProvider).progressBarState.current;
    // 播放控制器
    final player = ref.read(playerControllerProvider.notifier);

    // 无字幕：直接显示占位，不触发 family 请求
    if (lyricUrl == null || lyricUrl.isEmpty) {
      return const Center(child: Text("暂无字幕", style: TextStyle(color: Colors.white)));
    }

    // 按 URL 命中 family 缓存：同一 URL 只拉取一次
    final lyricsAsync = ref.watch(lyricsContentProvider(lyricUrl));

    return lyricsAsync.when(
      data: (lyricContent) {
        if (lyricContent == null || lyricContent.isEmpty) return const Center(child: Text("暂无字幕",style: TextStyle(color: Colors.white)));

        return ShowLyric(
          key: ValueKey(lyricContent.hashCode),
          progress: progressNotifier,
          initController: (controller) {
            controller.setOnTapLineCallback(
                  (duration) async => {
                controller.stopSelection(),
                await player.seek(duration),
                player.play(),
              },
            );
          },
          afterLyricBuilder: (lyricController, style) =>
          [
            LyricSelectionProgress2(
              controller: lyricController,
              onPlay: (SelectionState state) async {
                lyricController.stopSelection();
                await player.seek(state.duration);
                player.play();
              },
              style: style,
            ),
          ],
          lyricText: lyricContent,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => KikoenaiErrorRetryView(
        message: '字幕加载失败，请检查网络后重试',
        foregroundColor: Colors.white,
        onRetry: () => ref.invalidate(lyricsContentProvider(lyricUrl)),
      ),
    );
  }
}