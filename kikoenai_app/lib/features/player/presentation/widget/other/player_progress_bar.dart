import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_progress_modify.dart';

import '../../provider/player_controller_provider.dart';

class PlayerProgressBar extends ConsumerWidget {
  final bool showTimeLabel;

  const PlayerProgressBar({
    super.key,
    this.showTimeLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressBarState = ref.watch(playerControllerProvider.select((p) => p.progressBarState));
    final bool isBuffering = ref.watch(playerControllerProvider.select((p) => p.loading));
    const double barHeight = 3.0;
    const double thumbRadius = 6.0;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ProgressBar(
          barCapShape: BarCapShape.round,
          isLoading: isBuffering,
          barHeight: barHeight,
          baseBarColor: const Color.fromARGB(197, 255, 255, 255),
          timeLabelLocation: showTimeLabel
              ? TimeLabelLocation.below
              : TimeLabelLocation.none,
          timeLabelTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          thumbColor: Colors.white,
          progressBarColor: Colors.white,
          thumbGlowColor: Colors.white70,
          thumbCanPaintOutsideBar: true,
          draggingThumbRadius: 6,
          thumbGlowRadius: 6,
          thumbRadius: thumbRadius,
          progress: progressBarState.current,
          buffered: progressBarState.buffered,
          total: progressBarState.total,
          onSeek: (progressBarState.total != Duration.zero)
              ? ref.read(playerControllerProvider.notifier).seek
              : null,
        ));
  }
}