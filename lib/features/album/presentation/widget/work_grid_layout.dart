import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/features/album/data/model/work.dart';
import 'package:name_app/features/album/presentation/widget/work_card.dart';

/// 响应式卡片网格布局
class ResponsiveCardGrid extends StatelessWidget {
  final List<Work> work;
  const ResponsiveCardGrid({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);

    // 从布局策略中获取布局参数
    final columns = layoutStrategy.getColumnsCount(context);
    final horizontalSpacing = layoutStrategy.getColumnSpacing(context);
    final verticalSpacing = layoutStrategy.getRowSpacing(context);

    return SliverGrid.builder(
      itemCount: work.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: horizontalSpacing, // 左右间距
        mainAxisSpacing: verticalSpacing, // 上下间距
        childAspectRatio: 0.75, // 卡片比例
      ),
      itemBuilder: (context, index) {
        return WorkCard(work: work[index]);
      },
    );
  }
}
