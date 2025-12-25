import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';

import '../../../../core/widgets/loading/lottie_loading.dart';

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

    return SliverMainAxisGroup(
      slivers: [
        // 1. 内容区域 (负责触发加载)
        SliverGrid.builder(
          itemCount: work.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            // --- 核心修复：基于 Index 的触发逻辑 ---
            // 只有当渲染到最后一个 Item，且还有更多数据，且当前没有在加载时，才触发
            if (index == work.length - 1 && hasMore) {
              // 使用 postFrameCallback 确保不在 build 周期内直接 setState
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onLoadMore();
              });
            }
            // -------------------------------------

            return WorkCard(work: work[index]);
          },
        ),

        // 2. 底部 Footer 区域 (只负责显示，不负责逻辑)
        SliverToBoxAdapter(
          child: _buildFooter(context),
        ),
      ],
    );
  }

// ... 在 ResponsiveCardGrid 类中 ...

  Widget _buildFooter(BuildContext context) {
    // 1. 没有更多数据
    if (!hasMore && work.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    // 2. 加载中 / 待机中 (显示 Lottie)
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: LottieLoadingIndicator(
        size: 80, // Lottie 动画通常需要稍微大一点才看得清细节
      ),
    );
  }
}