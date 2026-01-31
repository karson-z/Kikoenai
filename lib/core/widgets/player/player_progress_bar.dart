import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/player_progress_modify.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';

class PlayerProgressBar extends ConsumerWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final progressBarState = state.progressBarState;

    final bool isBuffering = state.loading;

    // 提取高度常量，以便对齐
    const double barHeight = 3.0;
    const double thumbRadius = 6.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        ProgressBar(
          isLoading: isBuffering,
          barHeight: barHeight,
          baseBarColor: const Color.fromARGB(197, 255, 255, 255),
          timeLabelLocation: TimeLabelLocation.below,
          timeLabelTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          thumbColor: Colors.white,
          progressBarColor: Colors.white,
          thumbGlowColor: Colors.white70,
          thumbGlowRadius: 12,
          thumbRadius: thumbRadius,
          progress: progressBarState.current,
          buffered: progressBarState.buffered,
          total: progressBarState.total,
          // 优化逻辑：即使未播放(playing=false)，如果已经加载好资源，通常也允许拖动。
          // 只有在初始化(total为0)时才完全禁用。
          onSeek: (progressBarState.total != Duration.zero)
              ? ref.read(playerControllerProvider.notifier).seek
              : null,
        ),
      ],
    );
  }
}