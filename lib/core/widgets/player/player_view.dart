import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import '../player/provider/player_controller_provider.dart';
import '../../utils/data/colors_util.dart';
import '../image_box/simple_extended_image.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';

class MusicPlayerView extends ConsumerWidget {
  final VoidCallback? onQueuePressed;
  const MusicPlayerView({super.key, this.onQueuePressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);                 // <-- 核心状态
    final controller = ref.read(playerControllerProvider.notifier);    // <-- 控制器
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
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: SafeArea(child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),

          _topBar(controller),

          const SizedBox(height: 20),
          _cover(imageSize, state),

          const SizedBox(height: 28),
          _info(state),

          const SizedBox(height: 28),
          _progressBar(
            state,
                (value) => controller.seek(Duration(milliseconds: value.toInt())),
          ),

          const SizedBox(height: 30),
          _controls(controller, state),

          const SizedBox(height: 30),
          _volume(controller, state.volume),
        ],
      ),)
    );
  }

  // ----------------------------------------------------------------------
  // UI BLOCKS
  // ----------------------------------------------------------------------

  Widget _topBar(PlayerController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
              onTap: controller.stop,
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 30)),
          Text("正在播放",
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
          const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 26),
        ],
      ),
    );
  }

  Widget _cover(double size, PlayerState state) {
    final cover = state.currentTrack?.extras?['mainCoverUrl'] ?? placeholderImage;
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

  Widget _info(PlayerState state) {
    final item = state.currentTrack;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item?.title ?? "没有播放的曲目",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(item?.artist ?? "未知艺人",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _progressBar(
      PlayerState state,
      ValueChanged<double> onChanged,
      ) {
    final total = (state.currentTrack?.duration ?? Duration.zero).inMilliseconds.toDouble();
    final progress = state.position.inMilliseconds.clamp(0, total).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Slider(
            value: progress,
            min: 0,
            max: total == 0 ? 1 : total,
            onChanged: onChanged,
            activeColor: Colors.white,
            inactiveColor: Colors.white30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _time(state.position),
              _time(state.currentTrack?.duration ?? Duration.zero),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controls(PlayerController controller, PlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                controller.setRepeat(AudioServiceRepeatMode.one),
            icon: const Icon(Icons.repeat, color: Colors.white),
          ),

          IconButton(
            onPressed: state.isFirst ? null : controller.previous,
            icon: const Icon(Icons.skip_previous_rounded,
                color: Colors.white, size: 36),
          ),

          GestureDetector(
            onTap: () => state.playing
                ? controller.pause()
                : controller.play(),
            child: Icon(
              state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),

          IconButton(
            onPressed: state.isLast ? null : controller.next,
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

  Widget _volume(PlayerController controller, double volume) {
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
              onChanged: (v) => controller.setVolume(v),
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _time(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text("$mm:$ss",
        style: const TextStyle(color: Colors.white70, fontSize: 12));
  }
}
