import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/player_progress_bar.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../constants/app_images.dart';
import '../../utils/data/colors_util.dart';
import '../image_box/simple_extended_image.dart';
import '../layout/app_main_scaffold.dart';
import '../layout/provider/main_scaffold_provider.dart';

class MusicPlayerView extends ConsumerWidget {
  final VoidCallback? onQueuePressed;
  const MusicPlayerView({super.key, this.onQueuePressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 只监听 currentTrack（低频）
    final currentTrack = ref.watch(
      playerControllerProvider.select((s) => s.currentTrack),
    );

    final panelControl = ref.read(panelController);

    // 提取封面 URL 监听（低频）
    ref.listen<String?>(
      playerControllerProvider.select(
            (s) => s.currentTrack?.extras?['mainCoverUrl'] as String?,
      ),
          (prev, next) {
        if (next != null && next != prev) {
          ref.read(mainScaffoldProvider.notifier).fetchAlbumColors(next);
        }
      },
    );

    final bg = ref.watch(mainScaffoldProvider);
    final gradient = ColorUtils.buildGradient(
      start: bg.dominantColor,
      end: bg.vibrantColor.withOpacity(0.6),
      begin: Alignment.topCenter,
      endAlign: Alignment.bottomCenter,
    );

    final width = MediaQuery.of(context).size.width;
    final imageSize = width.clamp(260, 340).toDouble();

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SizedBox.expand(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 10),

            _topBar(ref, panelControl),

            const SizedBox(height: 20),
            _cover(imageSize, currentTrack),

            const SizedBox(height: 28),
            _info(currentTrack),

            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: PlayerProgressBar(),
            ),


            const SizedBox(height: 30),
            _controls(ref),

            const SizedBox(height: 30),
            _volume(ref),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------
  // 顶部
  // ------------------------------------------------------
  Widget _topBar(WidgetRef ref, PanelController panelControl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: panelControl.close,
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 30),
          ),
          Text("正在播放",
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
          const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 26),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // 封面
  // ------------------------------------------------------
  Widget _cover(double size, MediaItem? track) {
    final cover = track?.extras?['mainCoverUrl'] ?? placeholderImage;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(10, 10),
              blurRadius: 20,
              spreadRadius: -5,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SimpleExtendedImage(
            cover,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------
  // 标题 + 艺人
  // ------------------------------------------------------
  Widget _info(MediaItem? track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(track?.title ?? "没有播放的曲目",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(track?.artist ?? "未知艺人",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }


  // ------------------------------------------------------
  // 播放控制按钮（只监听 playing / isFirst / isLast）
  // ------------------------------------------------------
  Widget _controls(WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);

    final playing = ref.watch(
      playerControllerProvider.select((s) => s.playing),
    );

    final isFirst = ref.watch(
      playerControllerProvider.select((s) => s.isFirst),
    );

    final isLast = ref.watch(
      playerControllerProvider.select((s) => s.isLast),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                controller.setRepeat(AudioServiceRepeatMode.none),
            icon: const Icon(Icons.repeat, color: Colors.white),
          ),

          IconButton(
            onPressed: isFirst ? null : controller.previous,
            icon: const Icon(Icons.skip_previous_rounded,
                color: Colors.white, size: 36),
          ),

          GestureDetector(
            onTap: () => playing ? controller.pause() : controller.play(),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),

          IconButton(
            onPressed: isLast ? null : controller.next,
            icon: const Icon(Icons.skip_next_rounded,
                color: Colors.white, size: 36),
          ),

          IconButton(
            onPressed: onQueuePressed,
            icon: const Icon(Icons.queue_music_sharp, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // 音量（只监听 volume）
  // ------------------------------------------------------
  Widget _volume(WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);

    final volume = ref.watch(
      playerControllerProvider.select((s) => s.volume),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: volume,
              min: 0,
              max: 1,
              onChanged: controller.setVolume,
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}
