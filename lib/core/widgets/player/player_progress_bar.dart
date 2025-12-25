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

    // 1. 获取缓冲状态
    // 注意：你需要确保你的 state 中包含判断是否正在缓冲的逻辑。
    // 如果使用的是 just_audio，通常判断 processingState == ProcessingState.buffering
    // 这里假设 state 中有一个 isBuffering 属性，或者你可以根据 buffered 和 current 的关系来推断
    final bool isBuffering = state.loading;

    // 提取高度常量，以便对齐
    const double barHeight = 3.0;
    const double thumbRadius = 10.0; // 默认 thumb 半径通常约为 10，用于调整 Padding

    return Stack(
      alignment: Alignment.center,
      children: [
        // --- 底部：带有加载动画的轨道 ---
        // 只有在缓冲时才显示这个 LinearProgressIndicator
        if (isBuffering)
          Padding(
            // audio_video_progress_bar 默认左右会有 thumb 的 padding，
            // 为了让加载条和原来的轨道对齐，我们需要设置类似的 padding。
            padding: const EdgeInsets.symmetric(horizontal: thumbRadius),
            child: SizedBox(
              height: barHeight,
              child: LinearProgressIndicator(
                // 背景透明，只显示流动的动画颜色
                backgroundColor: Colors.transparent,
                // 设置动画颜色，建议使用半透明白色，以免喧宾夺主
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),

        // --- 顶部：交互式进度条 ---
        // 放在上面以确保 Thumb (滑块) 可以被点击和拖动
        ProgressBar(
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
          thumbGlowRadius: 20,
          // 如果正在缓冲，通常我们希望 thumb 不要遮挡住加载动画，或者可以稍微变小（可选）
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