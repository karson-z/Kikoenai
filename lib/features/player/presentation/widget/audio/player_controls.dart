import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_list_sheet.dart';
import 'package:kikoenai/features/player/presentation/widget/audio/player_mode_button.dart';
import '../../provider/player_controller_provider.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    final isFirst = ref.watch(playerControllerProvider.select((s) => s.isFirst));
    final isLast = ref.watch(playerControllerProvider.select((s) => s.isLast));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlayModeButton(),
            const SizedBox(width: 24),
            IconButton(
                color: Colors.white,
                disabledColor: Colors.white30,
                onPressed: isFirst ? null : controller.previous,
                icon: const Icon(Icons.skip_previous_rounded, size: 36)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => playing ? controller.pause() : controller.play(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 54,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
                color: Colors.white,
                disabledColor: Colors.white30,
                onPressed: isLast ? null : controller.next,
                icon: const Icon(Icons.skip_next_rounded, size: 36)),
            const SizedBox(width: 24),
            IconButton(
                onPressed: () => PlayerPlaylistSheet.show(context),
                icon: const Icon(Icons.queue_music_sharp, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class PlayerVolumeSlider extends ConsumerWidget {
  const PlayerVolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final volume = ref.watch(playerControllerProvider.select((s) => s.volume));

    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  padding: const EdgeInsets.all(16),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
              child: Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: controller.setVolume,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniControlButtons extends ConsumerWidget {
  const MiniControlButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    final controller = ref.read(playerControllerProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6.0,
      children: [
        GestureDetector(
          // 增加点击命中率，确保图标透明区域也能响应点击
          behavior: HitTestBehavior.opaque,
          onTap: controller.previous,
          child: const Icon(Icons.skip_previous),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => playing ? controller.pause() : controller.play(),
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.next,
          child: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

class MiniPlayButton extends ConsumerWidget {
  const MiniPlayButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    final controller = ref.read(playerControllerProvider.notifier);

    return IconButton(
        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
        iconSize: 32,
        color: Colors.white,
        onPressed: () => playing ? controller.pause() : controller.play());
  }
}