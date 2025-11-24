import 'package:flutter/material.dart';
import 'work_list_item_skeleton.dart';

class VerticalCardColumnSkeleton extends StatelessWidget {
  final double width;
  final double cardHeight;
  final double maxHeight;

  const VerticalCardColumnSkeleton({
    super.key,
    required this.width,
    this.cardHeight = 75,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: maxHeight,
      child: Column(
        children: const [
          SizedBox(height: 75, child: WorkListItemSkeleton()),
          SizedBox(height: 8),
          SizedBox(height: 75, child: WorkListItemSkeleton()),
          SizedBox(height: 8),
          SizedBox(height: 75, child: WorkListItemSkeleton()),
        ],
      ),
    );
  }
}
