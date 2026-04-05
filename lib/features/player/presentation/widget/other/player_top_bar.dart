import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_more_options_sheet.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_sleep_time_widget.dart';
import '../../provider/player_controller_provider.dart';

class TopBar extends ConsumerWidget {
  final VoidCallback onClose;

  const TopBar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 左侧：下拉关闭
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 28),
              onPressed: onClose,
            ),
          ),

          // 右侧：功能按钮组
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SleepTimerButton(),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {
                    showMoreOptions(context, currentTrack);
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
