import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SmartColorCardSkeleton extends StatelessWidget {
  final double width;
  final double borderRadius;

  const SmartColorCardSkeleton({
    super.key,
    this.width = 240,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    const double aspectRatio = 4 / 3;
    const double bottomHeight = 60;

    final double imageHeight = width / aspectRatio;
    final double totalHeight = imageHeight + bottomHeight;

    return Skeletonizer(
      enabled: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: totalHeight,
          color: Colors.grey.shade300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 图片占位
              Container(
                width: width,
                height: imageHeight,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
