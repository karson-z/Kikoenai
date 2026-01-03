import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';

class PlayModeButton extends ConsumerWidget {
  final double size;

  const PlayModeButton({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听播放器状态
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    const baseColor = Colors.white;

    // 根据状态决定图标和颜色
    IconData icon;
    Color iconColor;
    String tooltip;

    if (playerState.shuffleEnabled) {
      // 1. 随机播放：纯白
      icon = Icons.shuffle;
      iconColor = baseColor;
      tooltip = "随机播放";
    } else {
      // 根据循环模式判断
      switch (playerState.repeatMode) {
        case AudioServiceRepeatMode.one:
        // 2. 单曲循环：纯白
          icon = Icons.repeat_one;
          iconColor = baseColor;
          tooltip = "单曲循环";
          break;
        case AudioServiceRepeatMode.all:
        // 3. 列表循环：纯白
          icon = Icons.repeat;
          iconColor = baseColor;
          tooltip = "列表循环";
          break;
        case AudioServiceRepeatMode.none:
        // 4. 不循环：半透明白色 (看起来像灰色/禁用态)
          icon = Icons.repeat;
          iconColor = baseColor.withOpacity(0.4);
          tooltip = "不循环";
          break;
        default:
          icon = Icons.repeat;
          iconColor = baseColor;
          tooltip = "列表循环";
      }
    }

    return IconButton(
      icon: Icon(icon),
      iconSize: size,
      color: iconColor,
      tooltip: tooltip,
      onPressed: () {
        controller.cyclePlayMode();
      },
    );
  }
}