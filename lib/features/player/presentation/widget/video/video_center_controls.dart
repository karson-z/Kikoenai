import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/player_controller_provider.dart';

class VideoCenterControls extends ConsumerWidget {
  const VideoCenterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    if (state.loading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 48,
          color: Colors.white,
          icon: const Icon(Icons.replay_10_rounded),
          onPressed: () {
            final current = state.progressBarState.current;
            final target = current - const Duration(seconds: 10);
            controller.seek(target.isNegative ? Duration.zero : target);
          },
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () => state.playing ? controller.pause() : controller.play(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          iconSize: 48,
          color: Colors.white,
          icon: const Icon(Icons.forward_10_rounded),
          onPressed: () {
            final current = state.progressBarState.current;
            final total = state.progressBarState.total;
            final target = current + const Duration(seconds: 10);
            controller.seek(target > total ? total : target);
          },
        ),
      ],
    );
  }
}