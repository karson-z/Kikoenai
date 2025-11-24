import 'package:flutter/material.dart';
import 'package:name_app/features/album/presentation/widget/skeleton/v_card_c_skeleton.dart';

class WorkListHorizontalSkeleton extends StatelessWidget {
  const WorkListHorizontalSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    const cardHeight = 75.0;
    const maxCards = 3;
    const maxHeight = cardHeight * maxCards + (maxCards - 1) * spacing;

    return SizedBox(
      height: maxHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // 固定骨架列数
        separatorBuilder: (_, __) => const SizedBox(width: spacing),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 300, // 随便给一个骨架宽度，匹配你的真实布局即可
            child: const VerticalCardColumnSkeleton(
              width: 300,
              maxHeight: maxHeight,
            ),
          );
        },
      ),
    );
  }
}
