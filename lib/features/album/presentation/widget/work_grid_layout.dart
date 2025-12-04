import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';

/// 响应式卡片网格布局
class ResponsiveCardGrid extends StatelessWidget {
  final List<Work> work;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const ResponsiveCardGrid({
    super.key,
    required this.work,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);

    final horizontalSpacing = layoutStrategy.getColumnSpacing(context);
    final verticalSpacing = layoutStrategy.getRowSpacing(context);

    return SliverGrid.builder(
      itemCount: work.length + 1, // 多 1 个专门用来显示 footer
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: horizontalSpacing,
        mainAxisSpacing: verticalSpacing,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        // 到达列表最后一个 index → 触发加载更多
        if (index == work.length) {
          // 调用 loadMore（但不重复触发）
          if (hasMore) {
            onLoadMore();
          }
          return _buildFooter();
        }
        return WorkCard(work: work[index]);
      },
    );
  }

  Widget _buildFooter() {
    if (!hasMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "没有更多内容了",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}