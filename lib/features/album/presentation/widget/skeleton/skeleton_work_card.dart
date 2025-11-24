import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WorkCardSkeleton extends StatelessWidget {
  const WorkCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          const SizedBox(height: 8),

          // 标题
          Container(
            height: 16,
            width: double.infinity,
            color: Colors.white,
          ),

          const SizedBox(height: 6),

          // 副标题
          Container(
            height: 14,
            width: 120,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
