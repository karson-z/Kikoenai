import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/sort_options.dart';
import '../../album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../album/presentation/widget/work_grid_layout.dart';
import '../presentation/viewmodel/provider/category_data_provider.dart';
import '../presentation/viewmodel/provider/category_keep_alive.dart';

class CategoryListTab extends ConsumerStatefulWidget {
  final SortOrder sortOrder;
  final double? pinnedHeaderHeight;
  final bool isFilterOpen;

  const CategoryListTab({
    Key? key,
    required this.sortOrder,
    this.pinnedHeaderHeight,
    required this.isFilterOpen,
  }) : super(key: key);

  @override
  ConsumerState<CategoryListTab> createState() => _CategoryListTabState();
}

class _CategoryListTabState extends ConsumerState<CategoryListTab>
    with AutomaticKeepAliveClientMixin { // 1. 保持 AutomaticKeepAliveClientMixin
  @override
  void initState() {
    super.initState();
    // 首次加载时，立即将自己注册为活跃
    // 使用 microtask 避免在构建过程中修改 Provider
    Future.microtask(() {
      ref.read(keepAliveManagerProvider.notifier).markAsActive(widget.sortOrder);
    });
  }
  @override
  bool get wantKeepAlive {
    final activeList = ref.read(keepAliveManagerProvider);
    return activeList.contains(widget.sortOrder);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<List<SortOrder>>(keepAliveManagerProvider, (previous, next) {
      // 如果名单变了，检查由于 "我" 是否还应该活着
      // 这里的 updateKeepAlive 会触发 wantKeepAlive 的重新读取
      updateKeepAlive();
    });
    final manager = ref.read(keepAliveManagerProvider.notifier);
    // 只有当自己不是列表最后一个（最新的）时，才去刷新位置
    final list = ref.read(keepAliveManagerProvider);
    if (list.isEmpty || list.last != widget.sortOrder) {
      Future.microtask(() => manager.markAsActive(widget.sortOrder));
    }
    final worksAsync = ref.watch(categoryProvider(widget.sortOrder));
    final categoryController = ref.read(categoryProvider(widget.sortOrder).notifier);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: RefreshIndicator(
        edgeOffset: widget.pinnedHeaderHeight ?? 0,
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

  List<Widget> _buildCommonContent(
      AsyncValue worksAsync, dynamic controller) {
    return [
      worksAsync.when(
        // 6. 【关键优化】: skipLoadingOnRefresh: true
        // 这样在下拉刷新时，数据会保持在 data 状态，而不会跳到 loading 状态
        // 从而避免页面闪烁成“骨架屏”，用户只会看到头部的刷新圈圈在转。
        skipLoadingOnRefresh: true,

        data: (data) {
          // 如果数据为空，显示空状态（可选）
          if (data.works.isEmpty) {
            return const SliverToBoxAdapter(child: Center(child: Text("暂无数据")));
          }

          return ResponsiveCardGrid(
            work: data.works,
            hasMore: data.hasMore,
            onLoadMore: () {
              controller.loadMore();
            },
          );
        },

        // 7. 只有在【首次初始化】且没有数据时，才会显示骨架屏
        loading: () => const ResponsiveCardGridSkeleton(),

        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: Center(
              child: TextButton(
                onPressed: () => ref.refresh(categoryProvider(widget.sortOrder)),
                child: Text('加载失败: $e\n点击重试', textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
