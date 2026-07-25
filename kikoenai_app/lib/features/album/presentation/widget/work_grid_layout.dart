import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart'; // 引入三方库

import 'package:kikoenai/config/work_layout_config.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import '../../../../core/widgets/loading/lottie_loading.dart';

class ResponsiveCardGrid extends StatelessWidget {
  final List<Work> work;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const ResponsiveCardGrid({
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
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyView(),
      );
    }

    final layout = WorkLayoutConfig.card(context);

    return SliverMainAxisGroup(
      slivers: [
        // 2. 内容区域：现在变得极其干净，只负责纯粹的 UI 渲染
        SliverGrid.builder(
          itemCount: work.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: layout.horizontalSpacing,
            mainAxisSpacing: layout.verticalSpacing,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final item = work[index];
            return WorkCard(
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

        // 3. 底部 Footer：专门负责接管无限滚动的触发
        SliverToBoxAdapter(child: _buildFooter(context)),
      ],
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 54, color: Colors.grey),
          SizedBox(height: 16),
          Text("这里什么都没有哦", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (hasMore) {
      // ★ 核心改变：使用 VisibilityDetector 监听底部 Loading 是否露脸
      return VisibilityDetector(
        key: const Key('infinite-scroll-footer'),
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
        padding: EdgeInsets.symmetric(
          vertical: 24,
        ), // 增加 padding 保持与 Loading 高度一致
        child: Text(
          "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
