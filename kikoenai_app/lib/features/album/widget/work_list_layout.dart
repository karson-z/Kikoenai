import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/card/work_list_card.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../core/widgets/loading/lottie_loading.dart';

/// 最新作品"列表模式"的 Sliver 列表：使用 [WorkListCard] 逐行渲染，
/// 展示字段与网格卡片一致；底部带与 [ResponsiveCardGrid] 相同的
/// 无限滚动 Footer（滚动到底自动加载更多）。
class ResponsiveWorkList extends StatelessWidget {
  final List<Work> work;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const ResponsiveWorkList({
    super.key,
    required this.work,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 空状态拦截
    if (work.isEmpty && !hasMore) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('这里什么都没有哦', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // 2. 列表内容
        SliverList.builder(
          itemCount: work.length,
          itemBuilder: (context, index) {
            final item = work[index];
            return WorkListCard(
              id: item.id,
              title: item.title,
              name: item.name,
              circleName: item.circle?.name,
              mainCoverUrl: item.mainCoverUrl,
              heroTag: item.effectiveHeroTag,
              hasSubtitle: item.hasSubtitle,
              ageCategoryString: item.ageCategoryString,
              release: item.release,
              vas: item.vas,
              tags: item.tags,
              onTap: () {
                context.push(AppRoutes.detail, extra: {'work': item});
              },
            );
          },
        ),

        // 3. 底部 Footer：无限滚动触发
        SliverToBoxAdapter(child: _buildFooter(context)),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (hasMore) {
      return VisibilityDetector(
        key: const Key('infinite-scroll-footer-list'),
        onVisibilityChanged: (info) {
          // 当 Loading 动画露出屏幕超过 10% 时，无缝触发加载更多
          if (info.visibleFraction > 0.1) {
            onLoadMore();
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: LottieLoadingIndicator(message: "loading...", size: 80),
        ),
      );
    }

    // 没有更多数据了
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
