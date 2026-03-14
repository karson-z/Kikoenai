import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/player_controls.dart';

class CollapsedMinibar extends ConsumerWidget {
  final MediaItem? track;
  final VoidCallback onTap;

  const CollapsedMinibar({
    super.key,
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double leftPadding = 16.0 + 60.0 + 12.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: leftPadding),

          // 1. Expanded 会拿走所有能拿走的空间，无情地把后面的组件挤到最右边
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.title ?? "未播放",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  track?.artist ?? "未知艺人",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          ConstrainedBox(
            constraints: BoxConstraints(
              // 限制按钮组最多只能占屏幕宽度的 45%
              // 这样既能防止它撑爆屏幕（解决溢出），又能让 Expanded 把它推到最右边
              maxWidth: MediaQuery.of(context).size.width * 0.45,
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight, // 缩放时保持靠右对齐
              child: MiniControlButtons(),
            ),
          ),

          // 右侧安全边距
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}