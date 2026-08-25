import 'dart:ui';

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
    this.progressLabel,
    this.onPlayTap,
    this.playTooltip = 'Play',
  });

  final String imageUrl;

  final String title;

  final String? subtitle;

  final double aspectRatio;

  final VoidCallback? onTap;

  final Widget? footer;

  final double borderRadius;

  final EdgeInsets padding;

  final Color? backgroundColor;

  final BoxFit fit;

  final String? progressLabel;

  final VoidCallback? onPlayTap;

  final String playTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: _ImageContent(
                  imageUrl: imageUrl,
                  fit: fit,
                  progressLabel: progressLabel,
                  onPlayTap: onPlayTap,
                  playTooltip: playTooltip,
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.65,
                        ),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (footer != null) ...[const SizedBox(height: 10), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({
    required this.imageUrl,
    required this.fit,
    required this.progressLabel,
    required this.onPlayTap,
    required this.playTooltip,
  });

  final String imageUrl;
  final BoxFit fit;
  final String? progressLabel;
  final VoidCallback? onPlayTap;
  final String playTooltip;

  @override
  Widget build(BuildContext context) {
    final hasOverlay = progressLabel != null || onPlayTap != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        SimpleExtendedImage(imageUrl, fit: fit),
        if (progressLabel != null)
          Positioned(
            left: 10,
            right: onPlayTap == null ? 10 : 58,
            bottom: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  progressLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        if (onPlayTap != null)
          Positioned(
            right: 10,
            bottom: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.34),
              shape: CircleBorder(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPlayTap,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
