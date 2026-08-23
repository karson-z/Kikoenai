import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/card/work_list_card.dart';
import 'package:kikoenai/core/widgets/pagination/paging_indicators.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

/// 作品列表模式，由 [PagedSliverList] 自动触发下一页请求。
class ResponsiveWorkList extends StatelessWidget {
  final PagingState<int, Work> pagingState;
  final VoidCallback fetchNextPage;
  final String emptyMessage;

  const ResponsiveWorkList({
    super.key,
    required this.pagingState,
    required this.fetchNextPage,
    this.emptyMessage = '这里什么都没有哦',
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Work>(
      state: pagingState,
      fetchNextPage: fetchNextPage,
      builderDelegate: PagedChildBuilderDelegate<Work>(
        invisibleItemsThreshold: 3,
        itemBuilder: (context, item, index) {
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
        firstPageProgressIndicatorBuilder: (_) =>
            const PagingProgressIndicator(),
        newPageProgressIndicatorBuilder: (_) => const PagingProgressIndicator(),
        firstPageErrorIndicatorBuilder: (_) =>
            PagingFirstPageErrorIndicator(onRetry: fetchNextPage),
        newPageErrorIndicatorBuilder: (_) =>
            PagingNewPageErrorIndicator(onRetry: fetchNextPage),
        noItemsFoundIndicatorBuilder: (_) =>
            PagingEmptyIndicator(message: emptyMessage),
        noMoreItemsIndicatorBuilder: (_) => const PagingNoMoreItemsIndicator(),
      ),
    );
  }
}
