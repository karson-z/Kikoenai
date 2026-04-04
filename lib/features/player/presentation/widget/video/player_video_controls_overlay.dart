import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_top_bar.dart';

import '../../provider/player_controller_provider.dart';
import '../other/player_list_sheet.dart';
import '../other/player_more_widget.dart';
import '../other/player_progress_bar.dart';

class PlayerVideoControlsOverlay extends ConsumerWidget {
  const PlayerVideoControlsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(playerControllerProvider).isVideoControlsVisible;
    final controller = ref.read(playerControllerProvider.notifier);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: controller.toggleControlsVisibility,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !isVisible,
          child: Container(
            color: Colors.black38,
            child: const SafeArea(
              child: Column(
                children: [
                  VideoTopBar(),
                  Expanded(
                    child: Center(
                      child: VideoCenterControls(
                      ),
                    ),
                  ),
                  VideoBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class VideoTopBar extends ConsumerWidget {

  const VideoTopBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：关闭/收起按钮
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
            onPressed: () {
              ref.read(panelControllerProvider).close();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
            onPressed: () {
              // MoreOptionsBottomSheet.(context);
            },
          ),
        ],
      ),
    );
  }
}
class VideoCenterControls extends ConsumerWidget {
  const VideoCenterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    if (state.loading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return GestureDetector(
      onTap: () {
        controller.startControlsHideTimer();
        state.playing ? controller.pause() : controller.play();
      },
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
    );
  }
}

class VideoBottomBar extends ConsumerWidget {
  const VideoBottomBar({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0
        ? '$hours:${minutes.padLeft(2, '0')}:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (_) => controller.startControlsHideTimer(), // 重置定时器
            child: const PlayerProgressBar(
              showTimeLabel: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: Colors.white,
                  disabledColor: Colors.white30,
                  onPressed: state.isFirst
                      ? null
                      : () {
                    controller.startControlsHideTimer(); // 重置定时器
                    controller.previous();
                  },
                ),
                IconButton(
                  icon: Icon(
                    state.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: () {
                    controller.startControlsHideTimer(); // 重置定时器
                    state.playing ? controller.pause() : controller.play();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  color: Colors.white,
                  disabledColor: Colors.white30,
                  onPressed: state.isLast
                      ? null
                      : () {
                    controller.startControlsHideTimer(); // 重置定时器
                    controller.next();
                  },
                ),
                const SizedBox(width: 8),
                if (defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    defaultTargetPlatform == TargetPlatform.linux) ...[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: Icon(
                      state.volume == 0
                          ? Icons.volume_off_rounded
                          : (state.volume < 0.5
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.startControlsHideTimer(); // 重置定时器
                      controller.setVolume(state.volume == 0 ? 1.0 : 0.0);
                    },
                  ),
                  SizedBox(
                    width: 80,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10),
                      ),
                      child: Slider(
                        value: state.volume,
                        min: 0,
                        max: 1,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        onChanged: (val) {
                          controller.startControlsHideTimer(); // 重置定时器
                          controller.setVolume(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${_formatDuration(state.progressBarState.current)} / ${_formatDuration(state.progressBarState.total)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted_rounded,
                      color: Colors.white),
                  onPressed: () {
                    controller.startControlsHideTimer(); // 重置定时器
                    PlayerPlaylistSheet.show(context);
                  },
                ),
                IconButton(
                  icon: Icon(
                    state.isVideoFullScreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    controller.startControlsHideTimer(); // 重置定时器
                    controller.toggleVideoFullScreen();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}