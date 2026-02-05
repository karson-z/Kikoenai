import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/player_lyrics_widget.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:kikoenai/core/widgets/player/provider/player_lyrics_provider.dart';
import 'package:flutter_lyric/flutter_lyric.dart';

class LyricsPanel extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const LyricsPanel({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  @override
  Widget build(BuildContext context) {
    // 监听解析后的字幕数据
    final lyricsAsync = ref.watch(lyricsProvider);
    // 监听当前进度提供给flutter_lyrics 使用
    final progressNotifier = ref.watch(playerControllerProvider).progressBarState.current;
    // 播放控制器
    final player = ref.read(playerControllerProvider.notifier);

    return lyricsAsync.when(
      data: (lyricContent) {
        if ((lyricContent != null && lyricContent.isEmpty) || lyricContent == null) return const Center(child: Text("暂无字幕"));

        return GestureDetector(
          onTap: widget.onTap,
          child: ShowLyric(
            initStyle: LyricStyles.default2,
            progress: progressNotifier,
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("加载失败: $err")),
    );
  }
}