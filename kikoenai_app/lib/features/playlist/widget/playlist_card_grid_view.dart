import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:kikoenai/config/work_layout_config.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/pagination/paging_indicators.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';

class PlaylistCardGridView extends StatelessWidget {
  final PagingState<int, Work> pagingState;
  final VoidCallback fetchNextPage;

  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const PlaylistCardGridView({
    super.key,
    required this.pagingState,
    required this.fetchNextPage,
    this.scrollController,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final layout = WorkLayoutConfig.card(context);

    return PagedGridView<int, Work>(
      state: pagingState,
      fetchNextPage: fetchNextPage,
      scrollController: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      showNewPageProgressIndicatorAsGridChild: false,
      showNewPageErrorIndicatorAsGridChild: false,
      showNoMoreItemsIndicatorAsGridChild: false,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: layout.horizontalSpacing,
        mainAxisSpacing: layout.verticalSpacing,
        childAspectRatio: 0.75,
      ),
      builderDelegate: PagedChildBuilderDelegate<Work>(
        invisibleItemsThreshold: 3,
        itemBuilder: (context, item, index) {
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
        firstPageProgressIndicatorBuilder: (_) =>
            const PagingProgressIndicator(),
        newPageProgressIndicatorBuilder: (_) => const PagingProgressIndicator(),
        firstPageErrorIndicatorBuilder: (_) =>
            PagingFirstPageErrorIndicator(onRetry: fetchNextPage),
        newPageErrorIndicatorBuilder: (_) =>
            PagingNewPageErrorIndicator(onRetry: fetchNextPage),
        noItemsFoundIndicatorBuilder: (_) =>
            const PagingEmptyIndicator(message: '没有找到相关作品'),
        noMoreItemsIndicatorBuilder: (_) => const PagingNoMoreItemsIndicator(),
      ),
    );
  }
}
