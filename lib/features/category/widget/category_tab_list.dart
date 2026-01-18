import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/sort_options.dart';
import '../../album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../album/presentation/widget/work_grid_layout.dart';
import '../presentation/viewmodel/provider/category_data_provider.dart';

class CategoryListTab extends ConsumerStatefulWidget {
  final SortOrder sortOrder; // 当前 Tab 的排序方式
  final double pinnedHeaderHeight; // 顶部固定的高度，用于 RefreshIndicator
  final bool isFilterOpen; // 筛选面板状态，控制滚动

  const CategoryListTab({
    Key? key,
    required this.sortOrder,
    required this.pinnedHeaderHeight,
    required this.isFilterOpen,
  }) : super(key: key);

  @override
  ConsumerState<CategoryListTab> createState() => _CategoryListTabState();
}

class _CategoryListTabState extends ConsumerState<CategoryListTab>
    with AutomaticKeepAliveClientMixin { // 1. 混入 KeepAlive

  @override
  bool get wantKeepAlive => true; // 2. 开启保活

  @override
  Widget build(BuildContext context) {
    super.build(context); // 3. 必须调用

    final worksAsync = ref.watch(categoryProvider(widget.sortOrder));
    final categoryController = ref.read(categoryProvider(widget.sortOrder).notifier);

    return ScrollConfiguration(
      // 禁用默认的 Scrollbar，防止它去监听共享的 Controller 导致崩溃
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),

      child: RefreshIndicator(
        edgeOffset: widget.pinnedHeaderHeight,
        onRefresh: () async {
          return ref.refresh(categoryProvider(widget.sortOrder).future);
        },
        child: CustomScrollView(
          key: PageStorageKey<String>(widget.sortOrder.label),
          physics: widget.isFilterOpen
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            ..._buildCommonContent(worksAsync, categoryController),
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  // 辅助方法：构建列表内容
  List<Widget> _buildCommonContent(
      AsyncValue worksAsync, dynamic controller) {
    return [
      worksAsync.when(
        data: (data) => ResponsiveCardGrid(
          work: data.works,
          hasMore: data.hasMore,
          onLoadMore: () {
            controller.loadMore();
          },
        ),
        loading: () => const ResponsiveCardGridSkeleton(),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: Center(
              child: Text('加载失败: $e', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    ];
  }
}