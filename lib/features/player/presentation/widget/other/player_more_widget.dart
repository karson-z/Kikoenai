import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/player/data/model/playback_session.dart';

class MoreOptionsBottomSheet extends StatelessWidget {
  final PlaybackItem track;
  final List<QuickActionItem> quickActions;
  final List<ListActionItem> listActions;

  const MoreOptionsBottomSheet({
    super.key,
    required this.track,
    required this.quickActions,
    required this.listActions,
  });

  @override
  Widget build(BuildContext context) {
    // 只需要拿到 theme，所有的颜色都会自动派生
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final secondaryColor = colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 歌曲信息头部
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 专辑封面
              SimpleExtendedImage(
                borderRadius: BorderRadius.circular(8),
                track.coverUrl ?? track.smallCoverUrl ?? "",
                width: 60,
                height: 60,
              ),
              const SizedBox(width: 16),
              // 标题和歌手
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // 使用主题的 titleMedium，自动适配黑白字
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist ?? '未知作者',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // 使用衍生出的次要颜色
                      style: textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        // 2. 快捷操作按钮区 (收藏、文件管理等)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: quickActions.map((action) {
              return _buildActionButton(action, theme);
            }).toList(),
          ),
        ),

        const Divider(),

        // 3. 列表菜单区
        ...listActions.map((item) {
          return _buildListItem(item, theme, secondaryColor);
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // 构建功能按钮
  Widget _buildActionButton(QuickActionItem action, ThemeData theme) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon 默认就会使用当前主题的颜色，无需手动传色
            Icon(action.icon, size: 28),
            const SizedBox(height: 8),
            Text(action.label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // 内部组件构建方法
  Widget _buildListItem(
    ListActionItem item,
    ThemeData theme,
    Color secondaryColor,
  ) {
    bool currentSwitchValue = item.initialSwitchValue;

    return StatefulBuilder(
      builder: (context, setState) {
        return InkWell(
          onTap: item.hasSwitch
              ? () {
                  setState(() => currentSwitchValue = !currentSwitchValue);
                  item.onSwitchChanged?.call(currentSwitchValue);
                }
              : item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Text(item.title, style: theme.textTheme.titleSmall),
                      if (item.subtitle != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.hasSwitch)
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: currentSwitchValue,
                      // 主题色高亮，直接读 colorScheme.primary
                      activeTrackColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        setState(() => currentSwitchValue = val);
                        item.onSwitchChanged?.call(val);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 数据驱动模型保持不变...
class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ListActionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool hasSwitch;
  final bool initialSwitchValue;
  final ValueChanged<bool>? onSwitchChanged;

  ListActionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.hasSwitch = false,
    this.initialSwitchValue = false,
    this.onSwitchChanged,
  });
}
