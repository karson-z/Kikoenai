import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';

class MoreOptionsBottomSheet extends StatelessWidget {
  final MediaItem track;

  const MoreOptionsBottomSheet({super.key, required this.track});

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SimpleExtendedImage(
                      track.extras!['mainCoverUrl'],
                      width: 60,
                      height: 60,
                    )
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
                  // [移除] 原图右上角的 VIP 和心动按钮
                ],
              ),
            ),

            Divider(height: 1, color: dividerColor),

            // 2. 功能按钮栏 (移除 "一起听")
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.add_box_outlined, "收藏", iconColor!, primaryTextColor),
                  _buildActionButton(Icons.download_for_offline_outlined, "下载", iconColor, primaryTextColor),
                  _buildActionButton(Icons.share_outlined, "分享", iconColor, primaryTextColor),
                  _buildActionButton(Icons.screen_rotation_outlined, "横屏", iconColor, primaryTextColor),
                ],
              ),
            ),

            Divider(height: 1, color: dividerColor),

            // 3. 信息列表
            _buildListItem(Icons.album_outlined, "专辑", track.album, iconColor, primaryTextColor, secondaryTextColor!),
            _buildListItem(Icons.person_outline_rounded, "歌手", track.artist, iconColor, primaryTextColor, secondaryTextColor),
            _buildListItem(Icons.info_outline_rounded, "查看歌曲百科", null, iconColor, primaryTextColor, secondaryTextColor),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 构建功能按钮 (收藏、下载等)
  Widget _buildActionButton(IconData icon, String label, Color iconColor, Color textColor) {
    return InkWell(
      onTap: () {
        // TODO: 处理点击事件
        print("点击了: $label");
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  // 构建列表项 (专辑、歌手等)
  Widget _buildListItem(IconData icon, String title, String? subtitle, Color iconColor, Color titleColor, Color subtitleColor) {
    return InkWell(
      onTap: () {
        // TODO: 处理点击事件
        print("点击了: $title");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: titleColor),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtitle,
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