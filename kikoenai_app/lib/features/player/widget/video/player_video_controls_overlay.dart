import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';

import '../../../../../core/widgets/layout/provider/main_scaffold_provider.dart';
import '../../provider/player_controller_provider.dart';
import '../other/player_list_sheet.dart';
import '../other/player_more_options_sheet.dart';
import '../other/player_progress_bar.dart';

class PlayerVideoControlsOverlay extends ConsumerWidget {
  const PlayerVideoControlsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(
      playerControllerProvider.select((p) => p.isVideoControlsVisible),
    );
    const duration = Duration(milliseconds: 250);
    const curve = Curves.easeOutCubic;

    return IgnorePointer(
      ignoring: !isVisible,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedSlide(
                  offset: isVisible ? Offset.zero : const Offset(0, -1.2),
                  duration: duration,
                  curve: curve,
                  child: AnimatedOpacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    duration: duration,
                    child: const VideoTopBar(),
                  ),
                ),
                AnimatedSlide(
                  offset: isVisible ? Offset.zero : const Offset(0, 1.2),
                  duration: duration,
                  curve: curve,
                  child: AnimatedOpacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    duration: duration,
                    child: const VideoBottomBar(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoTopBar extends ConsumerWidget {
  const VideoTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItem = ref.watch(
      playerControllerProvider.select((p) => p.currentItem),
    );
    final controller = ref.read(playerControllerProvider.notifier);

    return MouseRegion(
      onEnter: (_) => controller.cancelControlsHideTimer(),
      onExit: (_) => controller.startControlsHideTimer(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  ref.read(panelControllerProvider).close();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  showMoreOptions(context, ref, currentItem);
                },
              ),
            ],
          ),
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
    final isFullScreen = ref.watch(mainScaffoldProvider).isFullScreen;

    return MouseRegion(
      onEnter: (_) => controller.cancelControlsHideTimer(),
      onExit: (_) => controller.startControlsHideTimer(),
      child: Container(
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
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => controller.startControlsHideTimer(),
              onPointerMove: (_) => controller.startControlsHideTimer(),
              onPointerUp: (_) => controller.startControlsHideTimer(),
              onPointerCancel: (_) => controller.startControlsHideTimer(),
              child: const PlayerProgressBar(showTimeLabel: false),
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
                            controller.startControlsHideTimer();
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
                      controller.startControlsHideTimer();
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
                            controller.startControlsHideTimer();
                            controller.next();
                          },
                  ),
                  const SizedBox(width: 8),
                  if (defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.linux) ...[
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
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
                        controller.startControlsHideTimer();
                        controller.setVolume(state.volume == 0 ? 1.0 : 0.0);
                      },
                    ),
                    SizedBox(
                      width: 80,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: state.volume,
                          min: 0,
                          max: 1,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (val) {
                            controller.startControlsHideTimer();
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
                    icon: const Icon(
                      Icons.format_list_bulleted_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      controller.startControlsHideTimer();
                      PlayerPlaylistSheet.show(context);
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      controller.startControlsHideTimer();
                      controller.toggleVideoFullScreen();
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          isFullScreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                        ),
                        Positioned(
                          right: -6,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54, // 半透明背景以适应不同视频画面
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isFullScreen
                                ? null
                                : Text(
                                    state.isVideoPortrait ? '竖' : '横',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
