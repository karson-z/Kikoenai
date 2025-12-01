import 'package:flutter/material.dart';
import 'package:kikoenai/features/album/presentation/widget/skeleton/smart_card_skeleton.dart';

class ResponsiveHorizontalCardListSkeleton extends StatelessWidget {
  final int itemCount;
  final double cardWidth;
  final double spacing;

  const ResponsiveHorizontalCardListSkeleton({
    super.key,
    this.itemCount = 6,
    this.cardWidth = 180,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    const double aspectRatio = 4 / 3;
    const double bottomHeight = 60;
    final double cardHeight = cardWidth / aspectRatio + bottomHeight;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            width: cardWidth,
            child: const SmartColorCardSkeleton(),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: spacing),
      ),
    );
  }
}
