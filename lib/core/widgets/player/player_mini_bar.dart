import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import '../../theme/theme_view_model.dart';

class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;
  const MiniPlayer({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final bg = ref.watch(mainScaffoldProvider);
    final playerState = ref.watch(playerControllerProvider);
    final playController = ref.watch(playerControllerProvider.notifier);
    bool isDark = themeState.value?.mode == ThemeMode.dark ||
        (themeState.value?.mode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final baseColor = isDark ? Colors.black : Colors.white;
    final progressColor = bg.dominantColor;
    final total = (playerState.currentTrack?.duration ?? Duration.zero).inMilliseconds.toDouble();
    final progressValue = total == 0 ? 0.0 : (playerState.position.inMilliseconds / total).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              progressColor,                        // 已播放区域主色
              progressColor,       // 渐变到未播放区
              baseColor,                            // 未播放区浅色
              baseColor,                            // 未播放区底色
            ],
            stops: [
              0.0,
              progressValue,    // 渐变结束在播放进度位置
              progressValue + 0.03, // 让过渡稍微柔和一点
              1.0,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),

        ),
        child: Row(
          children: [
            // 小封面
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SimpleExtendedImage(
                playerState.currentTrack?.extras?["samCorverUrl"] ?? placeholderImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // 标题 + 艺术家
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerState.currentTrack?.title ?? "歌曲列表为空",
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    playerState.currentTrack?.artist ?? "未知艺人",
                    style: TextStyle(
                        color: textColor.withOpacity(0.7), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                playController.previous();
              },
              icon: Icon(Icons.skip_previous_rounded, color: iconColor),
              iconSize: 24,
            ),
            IconButton(
              onPressed: () {
                playerState.playing ? playController.pause() : playController.play();
              },
              icon: Icon(
                  playerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: iconColor),
              iconSize: 30,
            ),
            IconButton(
              onPressed: () {
                playController.next();
              },
              icon: Icon(Icons.skip_next_rounded, color: iconColor),
              iconSize: 24,
            ),
          ],
        ),
      ),
    );
  }
}
