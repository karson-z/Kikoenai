import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../../provider/player_view_controller.dart';
import '../lyrics/player_lyrics_content.dart';
import '../other/player_top_bar.dart';
import '../player_layout.dart';
import 'player_playback_page.dart';

class PlayerAudioContent extends StatefulWidget {
  const PlayerAudioContent({
    super.key,
    required this.track,
    required this.metrics,
    required this.controller,
    required this.onClose,
  });

  final PlaybackItem? track;
  final PlayerLayoutMetrics metrics;
  final PlayerViewController controller;
  final VoidCallback onClose;

  @override
  State<PlayerAudioContent> createState() => _PlayerAudioContentState();
}

class _PlayerAudioContentState extends State<PlayerAudioContent> {
  // Reparent both pages in the same frame when crossing the breakpoint.
  final _playbackKey = GlobalKey();
  final _lyricsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final playback = _KeptAlivePage(
      key: _playbackKey,
      child: PlayerPlaybackPage(track: widget.track, metrics: metrics),
    );
    final lyrics = _KeptAlivePage(
      key: _lyricsKey,
      child: PlayerLyricsContent(
        track: widget.track,
        showHeader: metrics.isPaged,
        headerHeight: metrics.lyricsHeaderHeight,
        contentSize: metrics.lyricsFrame.size,
      ),
    );

    return Stack(
      children: [
        if (metrics.isPaged)
          Positioned.fromRect(
            rect: metrics.content,
            child: PageView(
              key: const ValueKey('player-page-view'),
              controller: widget.controller.pageController,
              onPageChanged: widget.controller.rememberPage,
              // Also keeps the adjacent page mounted for same-frame
              // reparenting when switching between layout modes.
              allowImplicitScrolling: true,
              children: [playback, lyrics],
            ),
          )
        else
          Positioned.fill(
            child: Stack(
              key: ValueKey(
                metrics.mode == PlayerLayoutMode.sideBySide
                    ? 'player-split-view'
                    : 'player-stacked-view',
              ),
              children: [
                Positioned.fromRect(
                  rect: metrics.playbackViewport,
                  child: playback,
                ),
                Positioned.fromRect(
                  rect: metrics.lyricsViewport,
                  child: lyrics,
                ),
              ],
            ),
          ),
        Positioned.fromRect(
          rect: metrics.topBar,
          child: RepaintBoundary(child: TopBar(onClose: widget.onClose)),
        ),
      ],
    );
  }
}

class _KeptAlivePage extends StatefulWidget {
  const _KeptAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<_KeptAlivePage> createState() => _KeptAlivePageState();
}

class _KeptAlivePageState extends State<_KeptAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
