import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/player_controls.dart';

import '../../../../core/widgets/player/player_lyrics_panel.dart';

class MobileLyricsContent extends ConsumerWidget {
  final MediaItem? track;
  final VoidCallback onTapHeader;
  final EdgeInsets padding;

  const MobileLyricsContent({super.key,
    required this.track,
    required this.onTapHeader,
    required this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 对应 LayoutDelegate 中的 lyricsHeaderTop 计算逻辑
    // 为了让 Header 文字和左侧浮动小图对齐，我们需要精确控制顶部间距
    const double lyricsHeaderSize = 50.0;
    // 之前的计算公式：padding.top + 70 + (60 - lyricsHeaderSize) / 2
    // 这里我们直接用 SizedBox 顶下来
    final double headerTopMargin = padding.top + 70;

    return Column(
      children: [
        SizedBox(height: headerTopMargin),

        // Header Area
        GestureDetector(
          onTap: onTapHeader,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 60, // 固定高度
            child: Row(
              children: [
                // 1. 左侧占位符：给浮动小封面留位置
                // expandedLyricsRect 的 left 是 24.0，width 是 50.0
                const SizedBox(width: 24 + 50 + 12),

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