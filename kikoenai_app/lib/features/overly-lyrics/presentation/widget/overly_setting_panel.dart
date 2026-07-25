import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/overly_lyrics_provider.dart';

class SubtitleConfigBottomSheet extends ConsumerWidget {
  const SubtitleConfigBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lyricsControllerProvider);
    final controller = ref.read(lyricsControllerProvider.notifier);

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '悬浮字幕设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('开启悬浮字幕'),
            subtitle: const Text('在系统顶层显示歌词'),
            value: state.isDesktopModeEnabled,
            onChanged: (val) {
              if (val) {
                controller.show();
              } else {
                controller.hide(isUserAction: true);
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('物理穿透锁定'),
            subtitle: const Text('锁定后鼠标/手势将穿透字幕'),
            value: state.isLocked,
            onChanged: (val) => controller.toggleLock(val,isMain: true),
          ),
        ],
      ),
    );
  }
}