import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../audio/player_controls.dart';
import '../player_layout.dart';
import 'player_lyrics_panel.dart';

class PlayerLyricsContent extends StatelessWidget {
  const PlayerLyricsContent({
    super.key,
    required this.track,
    required this.isWideScreen,
    required this.headerHeight,
  });

  final PlaybackItem? track;
  final bool isWideScreen;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isWideScreen)
          SizedBox(
            key: const ValueKey('player-lyrics-header'),
            height: headerHeight,
            child: Row(
              children: [
                // The shared cover lands here; the header itself is not a toggle.
                const SizedBox(
                  width:
                      PlayerLayoutMetrics.lyricsCoverLeft +
                      PlayerLayoutMetrics.lyricsCoverSize +
                      12,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track?.title ?? '未播放',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        track?.artist ?? '未知艺人',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const MiniPlayButton(),
                const SizedBox(width: 24),
              ],
            ),
          ),
        // A stable key preserves the lyric controller when the header appears.
        const Expanded(
          key: ValueKey('player-lyrics-panel'),
          child: LyricsPanel(),
        ),
      ],
    );
  }
}
