import 'package:flutter/material.dart';
import 'package:kikoenai/features/album/presentation/widget/skeleton/skeleton_work_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ResponsiveCardGridSkeleton extends StatelessWidget {
  const ResponsiveCardGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // 保持布局一致：同样的 spacing、同样的 Delegate
    // 因为 skeleton 阶段没有数据，这里可以给固定的占位个数
    return SliverGrid.builder(
      itemCount: 8, // 占位数量，你可自由调整
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return Skeletonizer(
          enabled: true,
          child: WorkCardSkeleton(),
        );
      },
    );
  }
}