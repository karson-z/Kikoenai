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
                RepaintBoundary(
                  child: PlayerBackground(expVal: expandedOpacity),
                ),
                TickerMode(
                  key: const ValueKey('player-audio-content'),
                  enabled: expansion > 0,
                  child: IgnorePointer(
                    ignoring: expansion < 0.95,
                    child: Opacity(opacity: expandedOpacity, child: child),
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
                PlayerCoverOverlay(
                  metrics: metrics,
                  expansion: expansion,
                  page: page,
                  coverUrl: currentItem?.displayCoverUrl,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
