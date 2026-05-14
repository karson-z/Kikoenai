import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';

class WorkGalleryCard extends StatelessWidget {
  const WorkGalleryCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.aspectRatio = 4 / 5,
    this.onTap,
    this.footer,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor,
    this.fit = BoxFit.cover,
  });

  /// 图片
  final String imageUrl;

  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 图片比例
  final double aspectRatio;

  /// 点击事件
  final VoidCallback? onTap;

  /// 底部扩展区域
  final Widget? footer;

  /// 圆角
  final double borderRadius;

  /// 内容 padding
  final EdgeInsets padding;

  /// 背景色
  final Color? backgroundColor;

  /// 图片填充方式
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.red,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 图片区域
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: SimpleExtendedImage(
                  imageUrl,
                  fit: fit,
                ),
              ),
            ),

            /// 信息区域
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 标题
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),

                  if (subtitle != null) ...[
                    const SizedBox(height: 6),

                    /// 副标题
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                  ],

                  if (footer != null) ...[
                    const SizedBox(height: 10),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}