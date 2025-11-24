// player_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/utils/data/other.dart';
import 'package:name_app/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:name_app/core/widgets/player/provider/player_controller_provider.dart';

import '../../utils/data/colors_util.dart';
import '../image_box/simple_extended_image.dart';

const String albumImageUrl = "https://picsum.photos/480";

class MusicPlayerView extends ConsumerStatefulWidget {
  final VoidCallback? onQueuePressed; // 父组件传入的回调
  const MusicPlayerView({super.key,this.onQueuePressed});

  @override
  ConsumerState<MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends ConsumerState<MusicPlayerView> {
  @override
  void initState() {
    super.initState();
    // 确保 build 完成后再初始化状态或发起网络请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bgColorController = ref.read(mainScaffoldProvider.notifier);
      bgColorController.fetchAlbumColors(albumImageUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double imageSize = width.clamp(260, 340).toDouble();
    // ✅ 只 watch 状态，不做副作用
    final bgColorState = ref.watch(mainScaffoldProvider);
    final playerState = ref.watch(playerNotifierProvider);
    final playerController = ref.read(playerNotifierProvider.notifier);
    final backgroundGradient = ColorUtils.buildGradient(
      start: bgColorState.dominantColor,
      end: bgColorState.vibrantColor.withOpacity(0.8),
      begin: Alignment.bottomCenter,
      endAlign: Alignment.topLeft,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColorState.dominantColor,
        gradient: backgroundGradient,
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                    onTap: playerController.minimizePlayer,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30)),
                Text(
                  "专辑名称",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
                GestureDetector(
                    onTap: playerController.showMoreOptions,
                    child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 26)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(10, 10),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SimpleExtendedImage(
                      playerState.currentWork?.mainCoverUrl ?? albumImageUrl,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 3.0,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerState.currentTrack?.title ?? "暂无歌曲",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  OtherUtil.joinVAs(playerState.currentWork?.vas),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: playerState.currentProgress,
                    min: 0,
                    max: 100,
                    onChanged: playerController.seek,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("01:32", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("04:28", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: playerController.toggleRepeat,
                  child: const Icon(Icons.repeat, color: Colors.white, size: 26),
                ),
                GestureDetector(
                  onTap: playerController.skipPrevious,
                  child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                ),
                GestureDetector(
                  onTap: playerController.togglePlayPause,
                  child: Icon(
                    playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: playerController.skipPrevious,
                  child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                ),
                GestureDetector(
                  onTap: (){
                    widget.onQueuePressed?.call();
                  },
                  child: const Icon(Icons.queue_music_sharp, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: playerState.currentVolume,
                      min: 0,
                      max: 100,
                      onChanged: playerController.changeVolume,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                    ),
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
