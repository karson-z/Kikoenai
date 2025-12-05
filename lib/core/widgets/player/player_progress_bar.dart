import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';

class PlayerProgressBar extends ConsumerWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final progressBarState = state.progressBarState;
    final playing = state.playing;

    return ProgressBar(
      barHeight: 3.0,
      baseBarColor: const Color.fromARGB(197, 255, 255, 255),
      timeLabelLocation: TimeLabelLocation.below,
      timeLabelTextStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
      ),
      thumbColor: Colors.white,
      progressBarColor: Colors.white,
      thumbGlowColor: Colors.white70,
      thumbGlowRadius: 20,
      progress: progressBarState.current,
      buffered: progressBarState.buffered,
      total: progressBarState.total,
      onSeek: playing
          ? ref.read(playerControllerProvider.notifier).seek
          : null,
    );
  }
}
