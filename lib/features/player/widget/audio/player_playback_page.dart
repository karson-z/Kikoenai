import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../other/player_progress_bar.dart';
import '../player_layout.dart';
import 'player_controls.dart';
import 'player_info.dart';

class PlayerPlaybackPage extends StatelessWidget {
  const PlayerPlaybackPage({
    super.key,
    required this.track,
    required this.metrics,
  });

  final PlaybackItem? track;
  final PlayerLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: metrics.coverSlot,
          child: const SizedBox(key: ValueKey('player-cover-slot')),
        ),
        _region(
          metrics.infoSlot,
          'player-info-region',
          PlayerInfoWidget(track: track, compact: metrics.isCompactSplit),
        ),
        _region(
          metrics.progressSlot,
          'player-progress-region',
          const PlayerProgressBar(),
          maxWidth: metrics.hasSharedControls
              ? double.infinity
              : PlayerLayoutMetrics.maxPlaybackWidth,
        ),
        _region(
          metrics.controlsSlot,
          'player-controls-region',
          const PlayerControls(),
        ),
        _region(
          metrics.volumeSlot,
          'player-volume-region',
          const PlayerVolumeSlider(),
        ),
      ],
    );
  }

  Widget _region(
    Rect rect,
    String key,
    Widget child, {
    double maxWidth = PlayerLayoutMetrics.maxPlaybackWidth,
  }) {
    return Positioned.fromRect(
      rect: rect,
      child: Center(
        key: ValueKey(key),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
