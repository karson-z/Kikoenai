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
            value: state.isShowing,
            onChanged: (val) {
              if (val) {
                controller.show();
              } else {
                controller.hide();
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('字体大小'),
            subtitle: Slider(
              value: state.fontSize,
              min: 12.0,
              max: 72.0,
              divisions: 60,
              label: state.fontSize.toInt().toString(),
              onChanged: (val) => controller.updateFontSize(val),
            ),
            trailing: Text(
              '${state.fontSize.toInt()} px',
              style: theme.textTheme.bodySmall,
            ),
          ),
          ListTile(
            title: const Text('背景透明度'),
            subtitle: Slider(
              value: state.opacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(state.opacity * 100).toInt()}%',
              onChanged: (val) => controller.setOpacity(val),
            ),
            trailing: Text(
              '${(state.opacity * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
          ),
          SwitchListTile(
            title: const Text('物理穿透锁定'),
            subtitle: const Text('锁定后鼠标/手势将穿透字幕'),
            value: state.isLocked,
            onChanged: (val) => controller.toggleLock(),
          ),
          SwitchListTile(
            title: const Text('允许自由拖拽'),
            value: state.isDraggable,
            onChanged: (val) => controller.setDraggable(val),
          ),
        ],
      ),
    );
  }
}