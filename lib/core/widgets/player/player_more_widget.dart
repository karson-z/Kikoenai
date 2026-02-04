import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';

class MoreOptionsBottomSheet extends StatelessWidget {
  final MediaItem track;
  final List<QuickActionItem> quickActions;
  final List<ListActionItem> listActions;

  const MoreOptionsBottomSheet(
      {super.key,
      required this.track,
      required this.quickActions,
      required this.listActions});

  @override
  Widget build(BuildContext context) {
    // 判断是否深色模式
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 背景色
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    // 主要文字颜色
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF333333);
    // 次要文字颜色
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600];
    // 图标颜色
    final iconColor = isDark ? Colors.white70 : Colors.grey[800];
    // 分割线颜色
    final dividerColor = isDark ? Colors.white10 : Colors.grey[200];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部把手
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 1. 歌曲信息头部
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // 专辑封面
                  SimpleExtendedImage(
                    borderRadius: BorderRadius.circular(8),
                    track.extras!['mainCoverUrl'],
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist ?? '未知作者',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickActions.map((action) {
                  return _buildActionButton(
                    action,
                    iconColor!,
                    primaryTextColor,
                  );
                }).toList(),
              ),
            ),
            Divider(height: 1, color: dividerColor),
            // 3. 信息列表
            ...listActions.map((item) {
              return _buildListItem(
                item,
                iconColor!,
                primaryTextColor,
                secondaryTextColor!,
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 构建功能按钮 (收藏、下载等)
  Widget _buildActionButton(QuickActionItem action, Color iconColor, Color textColor) {
    return InkWell(
      onTap: action.onTap, // 直接绑定传入的回调
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  // 内部组件构建方法 - 接收 ListActionItem 对象
  Widget _buildListItem(ListActionItem item, Color iconColor, Color titleColor, Color subtitleColor) {
    return InkWell(
      onTap: item.onTap, // 直接绑定传入的回调
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(item.icon, size: 24, color: iconColor),
            const SizedBox(width: 16),
            Text(
              item.title,
              style: TextStyle(fontSize: 16, color: titleColor),
            ),
            if (item.subtitle != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 数据驱动模型
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

// 用于底部列表项（专辑、歌手、百科）
class ListActionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  ListActionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
