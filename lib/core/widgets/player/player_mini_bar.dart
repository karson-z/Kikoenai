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
    final bg = ref.watch(mainScaffoldProvider);
    final playerState = ref.watch(playerControllerProvider);
    final playController = ref.watch(playerControllerProvider.notifier);
    final isDark = ref.watch(explicitDarkModeProvider);


    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final baseColor = isDark ? Colors.black : Colors.white;
    final progressColor = bg.dominantColor;
    final total = (playerState.progressBarState.total).inMilliseconds.toDouble();
    final progressValue = total == 0 ? 0.0 : (playerState.progressBarState.current.inMilliseconds / total).clamp(0.0, 1.0);

    const String placeholderImage = 'assets/images/placeholder.png'; // 替换为实际占位图路径

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // 外部 padding 保持不变
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              progressColor,
              progressColor,
              baseColor,
              baseColor,
            ],
            stops: [
              0.0,
              progressValue,
              progressValue + 0.01,
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
            // 1. 上一首
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0), // 减少水平内边距
              child: IconButton(
                onPressed: playController.previous,
                icon: Icon(Icons.skip_previous_rounded, color: iconColor),
                iconSize: 24,
                visualDensity: VisualDensity.compact, // 减小视觉密度
              ),
            ),
            // 2. 播放/暂停
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0), // 减少水平内边距
              child: IconButton(
                onPressed: () {
                  playerState.playing ? playController.pause() : playController.play();
                },
                icon: Icon(
                    playerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: iconColor),
                iconSize: 30,
                visualDensity: VisualDensity.compact, // 减小视觉密度
              ),
            ),
            // 3. 下一首
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0), // 减少水平内边距
              child: IconButton(
                onPressed: playController.next,
                icon: Icon(Icons.skip_next_rounded, color: iconColor),
                iconSize: 24,
                visualDensity: VisualDensity.compact, // 减小视觉密度
              ),
            ),
          ],
        ),
      ),
    );
  }
}