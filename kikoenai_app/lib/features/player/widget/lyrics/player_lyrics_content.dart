import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/features/player/widget/audio/player_controls.dart';
import 'package:kikoenai/features/player/widget/lyrics/player_lyrics_panel.dart';

class MobileLyricsContent extends ConsumerWidget {
  final PlaybackItem? track;
  final VoidCallback? onTapHeader;
  final EdgeInsets padding;
  final bool isWideScreen;

  const MobileLyricsContent({
    super.key,
    required this.track,
    this.onTapHeader,
    required this.isWideScreen,
    required this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double headerTopMargin = padding.top + 70;

    return Column(
      children: [
        SizedBox(height: headerTopMargin),

        if (!isWideScreen)
          GestureDetector(
            onTap: onTapHeader,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 60, // 固定高度
              child: Row(
                children: [
                  // 1. 左侧占位符：给浮动小封面留位置
                  // expandedLyricsRect 的 left 是 24.0，width 是 50.0
                  const SizedBox(width: 86),

                  // 2. 标题信息
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track?.title ?? "未播放",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          track?.artist ?? "未知艺人",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. 右侧迷你播放按钮
                  const MiniPlayButton(),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),

        // 歌词面板
        const Expanded(child: LyricsPanel()),
      ],
    );
  }
}
