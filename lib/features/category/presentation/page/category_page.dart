import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/filter_search_notifier.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../../../../../core/enums/sort_options.dart';
import '../../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../../data/model/filter_search_state.dart';
import '../../widget/category_tab_list.dart';
import '../../widget/filter_header_delegate.dart';
import '../../widget/filter_row_panel.dart';
import '../../../../core/widgets/filter/filter_widget.dart';
import '../viewmodel/provider/category_data_provider.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage>
    with SingleTickerProviderStateMixin {
  final List<SortOrder> sortOrders = SortOrder.values;
  late AutoScrollController _autoScrollController;
  late TabController _tabController;
  late FocusNode _filterSearchFocusNode;
  final double pinnedHeaderHeight = 90.0;

  @override
  void initState() {
    super.initState();

    final currentSort = ref.read(searchFilterProvider(FilterModule.category)).sortOption;
    int initialIndex = sortOrders.indexOf(currentSort);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: sortOrders.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _autoScrollController = AutoScrollController(axis: Axis.horizontal);
    _filterSearchFocusNode = FocusNode();

    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        final order = sortOrders[_tabController.index];
        // 切换 Tab 时，同步修改底层的排序状态
        ref.read(searchFilterProvider(FilterModule.category).notifier)
            .setSort(sortOption: order);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoScrollController.dispose();
    _filterSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取核心查询状态与控制器
    final query = ref.watch(searchFilterProvider(FilterModule.category));
    final queryNotifier = ref.read(searchFilterProvider(FilterModule.category).notifier);
    // 3. 获取数据状态 (带上当前的 sortOption family key)
    final currentTabAsync = ref.watch(categoryProvider(query.sortOption));
    final totalCount = currentTabAsync.value?.totalCount ?? 0;

    final isMobile = context.isMobile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 4. 定义主题色
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final Color primaryColor = theme.colorScheme.primary;

    // 监听选中标签数量，自动横向滚动筛选行
    ref.listen<SearchFilterState>(searchFilterProvider(FilterModule.category), (previous, next) {
      if (previous != null && next.selectedTags.length > previous.selectedTags.length) {
        final targetIndex = next.selectedTags.length - 1;
        _autoScrollController.scrollToIndex(
          targetIndex,
          preferPosition: AutoScrollPosition.end,
          duration: const Duration(milliseconds: 300),
        );
      }
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: bgColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            if (isMobile)
              SliverAppBar(
                expandedHeight: 80,
                floating: !query.isFilterOpen,
                snap: !query.isFilterOpen,
                backgroundColor: bgColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: MobileSearchAppBar(
                    onSearchTap: () {
                      context.push(AppRoutes.search);
                    },
                  ),
                ),
              ),

            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: FilterHeaderDelegate(
                  tabController: _tabController,
                  pinnedHeight: pinnedHeaderHeight,
                  sortOrders: sortOrders,

                  // 传递纯 UI 状态
                  sortDirection: query.sortDirection,
                  hasSubtitles: query.subtitleFilter == 1,

                  // 排序和字幕的点击事件：修改内存状态 -> 强制刷新当前 Tab 的数据源
                  onSortTap: () {
                    final nextSort = query.sortDirection == SortDirection.asc
                        ? SortDirection.desc
                        : SortDirection.asc;
                    queryNotifier.setSort(sortDec: nextSort);
                    ref.invalidate(categoryProvider(query.sortOption));
                  },
                  onSubtitleTap: () {
                    final nextSubtitle = query.subtitleFilter == 0 ? 1 : 0;
                    queryNotifier.setSubtitleFilter(nextSubtitle);
                    ref.invalidate(categoryProvider(query.sortOption));
                  },

                  // 直接构建并传入 FilterRowPanel
                  filterRowWidget: FilterRowPanel(
                    isFilterOpen: query.isFilterOpen,
                    keyword: query.keyword ?? "",
                    selectedTags: query.selectedTags,
                    totalCount: totalCount,

                    onToggleFilter: () {
                      _filterSearchFocusNode.unfocus();
                      queryNotifier.toggleFilterDrawer(); // 展开或收起顶层抽屉
                    },
                    onClearKeyword: () {
                      queryNotifier.updateKeyword(null);
                      ref.invalidate(categoryProvider(query.sortOption));
                    },
                    onRemoveTag: (tag) {
                      queryNotifier.removeTag(tag.type, tag.name);
                      if(!query.isFilterOpen){
                        ref.invalidate(categoryProvider(query.sortOption));
                      }
                    },

                    scrollController: _autoScrollController,
                    bgColor: bgColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    fillColor: fillColor,
                    primaryColor: primaryColor,
                  ),
                ),
              ),
            ),
          ],

          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: sortOrders.map((sortOrder) {
                  return CategoryListTab(
                    key: PageStorageKey<String>(sortOrder.label),
                    sortOrder: sortOrder,
                    pinnedHeaderHeight: pinnedHeaderHeight,
                    isFilterOpen: query.isFilterOpen,
                  );
                }).toList(),
              ),
              if (currentTabAsync.isRefreshing || currentTabAsync.isLoading)
                Positioned(
                  top: pinnedHeaderHeight,
                  left: 0,
                  right: 0,
                  child: const LinearProgressIndicator(
                    minHeight: 3.0,
                    backgroundColor: Colors.transparent,
                  ),
                ),

              // 遮罩层
              if (query.isFilterOpen)
                Positioned.fill(
                  top: pinnedHeaderHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _filterSearchFocusNode.unfocus();
                      queryNotifier.closeFilterDrawer();
                    },
                    child: Container(color: Colors.black12), // 稍微给点透明黑，交互更好
                  ),
                ),

              // 下拉筛选面板
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: pinnedHeaderHeight,
                left: 0,
                right: 0,
                height: query.isFilterOpen ? 450.0 : 0.0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: 450.0,
                    child: SizedBox(
                      height: 450.0,
                      child: Material(
                        color: bgColor,
                        elevation: 8.0,
                        shadowColor: Colors.black.withOpacity(0.2),
                        child: FilterWidget(
                          type: FilterModule.category,
                          // 点击底部的“完成”按钮触发
                          onComplete: () {
                            queryNotifier.closeFilterDrawer();
                            // 命令式刷新数据源
                            ref.invalidate(categoryProvider(query.sortOption));
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}