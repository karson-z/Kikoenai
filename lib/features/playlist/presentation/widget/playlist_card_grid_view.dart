import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';

import '../../../../core/widgets/loading/lottie_loading.dart';

class PlaylistCardGridView extends StatelessWidget {
  final List<Work> work;
  final bool hasMore;
  final VoidCallback onLoadMore;

  // 可选：允许外部传入 Controller 或 Padding
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const PlaylistCardGridView({
    super.key,
    required this.work,
    required this.hasMore,
    required this.onLoadMore,
    this.scrollController,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 空状态：直接返回普通的 Widget，不再需要 SliverFillRemaining
    if (work.isEmpty && !hasMore) {
      return _buildEmptyView();
    }

    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);
    final horizontalSpacing = layoutStrategy.getColumnSpacing(context);
    final verticalSpacing = layoutStrategy.getRowSpacing(context);

    // 2. 使用 CustomScrollView 封装，使其成为一个独立的滚动视图
    return CustomScrollView(
      controller: scrollController,
      // 保证即使内容很少也能滑动，以便触发刷新等操作
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 支持外部传入 Padding
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverGrid.builder(
            itemCount: work.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              crossAxisSpacing: horizontalSpacing,
              mainAxisSpacing: verticalSpacing,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              // 触发加载更多
              if (index == work.length - 1 && hasMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onLoadMore();
                });
              }
              return WorkCard(work: work[index]);
            },
          ),
        ),

        // 3. 底部 Footer
        SliverToBoxAdapter(
          child: _buildFooter(context),
        ),
      ],
    );
  }

  /// 普通的空状态视图 (Center 居中即可)
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
    // 底部稍微留点距离
    if (hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LottieLoadingIndicator(
          message: "loading...",
          size: 80,
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: 20, bottom: 40),
      child: Center(
        child: Text(
          "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}