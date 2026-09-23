import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/layout/app_main_scaffold.dart';
import '../provider/player_controller_provider.dart';
import '../provider/player_view_controller.dart';
import '../widget/audio/player_audio_content.dart';
import '../widget/audio/player_background.dart';
import '../widget/audio/player_cover_overlay.dart';
import '../widget/audio/player_mini_bar.dart';
import '../widget/player_layout.dart';
import '../widget/video/player_video_content.dart';

class PlayerView extends ConsumerStatefulWidget {
  const PlayerView({
    super.key,
    this.dragProgressNotifier,
    this.minHeight = 80.0,
  });

  final ValueListenable<double>? dragProgressNotifier;
  final double minHeight;

  @override
  ConsumerState<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<PlayerView> {
  late final PlayerViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlayerViewController(
      expandProgress: widget.dragProgressNotifier,
    );
  }

  @override
  void didUpdateWidget(covariant PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.updateExpandProgress(widget.dragProgressNotifier);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final currentItem = ref.watch(
      playerControllerProvider.select((state) => state.currentItem),
    );
    final shouldRenderVideo = ref.watch(
      playerControllerProvider.select((state) => state.isCurrentVideoView),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = PlayerLayoutMetrics(
          size: constraints.biggest,
          padding: mediaQuery.padding,
          textScaler: mediaQuery.textScaler,
          minHeight: widget.minHeight,
        );
        final audioContent = PlayerAudioContent(
          track: currentItem,
          metrics: metrics,
          controller: _controller,
          onClose: () => ref.read(panelControllerProvider).close(),
        );

        return AnimatedBuilder(
          animation: _controller,
          child: audioContent,
          builder: (context, child) {
            final expansion = _controller.expandValue;
            final miniOpacity = (1 - expansion * 5).clamp(0.0, 1.0);
            final expandedOpacity = ((expansion - 0.7) / 0.3).clamp(0.0, 1.0);
            final page = _controller.pageController.hasClients
                ? _controller.pageProgress
                : _controller.restingPage;

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                if (!shouldRenderVideo)
                  RepaintBoundary(
                    child: PlayerBackground(expVal: expandedOpacity),
                  ),
                // Keep the audio pages mounted while video is active, so changing
                // media type doesn't discard the reading position or selected page.
                Offstage(
                  key: const ValueKey('player-audio-content'),
                  offstage: shouldRenderVideo,
                  child: TickerMode(
                    enabled: !shouldRenderVideo && expansion > 0,
                    child: IgnorePointer(
                      ignoring: expansion < 0.95,
                      child: Opacity(opacity: expandedOpacity, child: child),
                    ),
                  ),
                ),
                if (shouldRenderVideo && expansion > 0.02)
                  Opacity(
                    opacity: expansion,
                    child: IgnorePointer(
                      ignoring: expansion < 0.5,
                      child: const RepaintBoundary(child: PlayerVideoContent()),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.minHeight,
                  child: IgnorePointer(
                    ignoring: miniOpacity < 0.05,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: CollapsedMinibar(
                        track: currentItem,
                        onTap: () => ref.read(panelControllerProvider).open(),
                      ),
                    ),
                  ),
                ),
                if (!shouldRenderVideo)
                  PlayerCoverOverlay(
                    metrics: metrics,
                    expansion: expansion,
                    page: page,
                    coverUrl: currentItem?.displayCoverUrl,
                  ),
                if (shouldRenderVideo && expansion <= 0.02)
                  Positioned.fromRect(
                    rect: metrics.collapsedCover,
                    child: const IgnorePointer(
                      child: PlayerVideoContent(isMini: true),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
