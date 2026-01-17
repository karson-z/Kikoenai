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
    // 1. 如果完全没有数据且没有更多了，显示“空状态”占满屏幕
    if (work.isEmpty && !hasMore) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyView(),
      );
    }

    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);
    final horizontalSpacing = layoutStrategy.getColumnSpacing(context);
    final verticalSpacing = layoutStrategy.getRowSpacing(context);

    return SliverMainAxisGroup(
      slivers: [
        // 2. 内容区域
        SliverGrid.builder(
          itemCount: work.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            // 触发加载更多的逻辑保持不变
            if (index == work.length-1 && hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onLoadMore();
              });
            }
            return WorkCard(work: work[index]);
          },
        ),

        // 3. 底部 Footer (负责 加载动画 或 到底提示)
        SliverToBoxAdapter(
          child: _buildFooter(context),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search_off, size: 54, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "这里什么都没有哦",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LottieLoadingIndicator(
          message: "loading...",
          size: 80,
        ),
      );
    }

    // 情况 B: 没有更多数据了 (且列表不为空，因为空的已经被上面 SliverFillRemaining 拦截了)
    return const Center(
      child: Text(
        "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}