import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../widget/category_tab_list.dart';
import '../widget/filter_header.dart';
import '../widget/filter_row_panel.dart';
import '../../../../core/widgets/filter/filter_widget.dart';
import '../provider/category_data_provider.dart';

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
  static const double _filterHeaderHeight = 90;
  @override
  void initState() {
    super.initState();
    final currentSort =
        ref.read(searchFilterProvider(FilterModule.category)).sortOption;
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
        final order = sortOrders[_tabController.index]; // 切换 Tab 时，同步修改底层的排序状态
        ref
            .read(searchFilterProvider(FilterModule.category).notifier)
            .setSort(sortOption: order); // 惰性刷新：仅当该 tab 缓存数据的筛选指纹与当前筛选不一致时才重新请求
        final ui = ref.read(searchFilterProvider(FilterModule.category));
        final lastFp =
            ref.read(categoryProvider(order)).value?.filterFingerprint;
        if (lastFp != null &&
            lastFp != CategoryDataNotifier.fingerprintOf(ui)) {
          ref.invalidate(categoryProvider(order));
        }
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
    final queryNotifier = ref.read(
      searchFilterProvider(FilterModule.category).notifier,
    ); // 3. 获取数据状态 (带上当前的 sortOption family key)
    final currentTabAsync = ref.watch(categoryProvider(query.sortOption));
    final totalCount = currentTabAsync.value?.totalCount ?? 0;
    final isMobile = context.isMobile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filterHeight = MediaQuery.sizeOf(context).height * 0.4; // 4. 定义主题色
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color fillColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final Color primaryColor = theme.colorScheme.primary; // 监听选中标签数量，自动横向滚动筛选行

    void completeFilter() {
      if (!query.isFilterOpen) return;
      queryNotifier.closeFilterDrawer();
      ref.invalidate(categoryProvider(query.sortOption));
    }

    ref.listen<SearchFilterState>(searchFilterProvider(FilterModule.category), (
      previous,
      next,
    ) {
      if (previous != null &&
          next.selectedTags.length > previous.selectedTags.length) {
        final targetIndex = next.selectedTags.length - 1;
        _autoScrollController.scrollToIndex(
          targetIndex,
          preferPosition: AutoScrollPosition.end,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
    final filterHeader = FilterHeader(
      height: _filterHeaderHeight,
      tabController: _tabController,
      sortOrders: sortOrders,
      sortDirection: query.sortDirection,
      hasSubtitles: query.subtitleFilter == 1,
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
      filterRow: FilterRowPanel(
        isFilterOpen: query.isFilterOpen,
        keyword: query.keyword ?? '',
        selectedTags: query.selectedTags,
        totalCount: totalCount,
        onToggleFilter: () {
          _filterSearchFocusNode.unfocus();
          if (query.isFilterOpen) {
            completeFilter();
          } else {
            queryNotifier.toggleFilterDrawer();
          }
        },
        onClearKeyword: () {
          queryNotifier.updateKeyword(null);
          ref.invalidate(categoryProvider(query.sortOption));
        },
        onRemoveTag: (tag) {
          queryNotifier.removeTag(tag.type, tag.name);
          if (!query.isFilterOpen) {
            ref.invalidate(categoryProvider(query.sortOption));
          }
        },
        scrollController: _autoScrollController,
        bgColor: bgColor,
        textColor: textColor,
        subTextColor: subTextColor,
        fillColor: fillColor,
        primaryColor: primaryColor,
        horizontalPadding: 8,
      ),
    );
    final categoryContent = Column(
      children: [
        filterHeader,
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: sortOrders.map((sortOrder) {
                  return CategoryListTab(
                    key: PageStorageKey<String>(sortOrder.label),
                    sortOrder: sortOrder,
                    isFilterOpen: query.isFilterOpen,
                  );
                }).toList(),
              ),
              if (currentTabAsync.isRefreshing || currentTabAsync.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (query.isFilterOpen)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _filterSearchFocusNode.unfocus();
                      completeFilter();
                    },
                    child: Container(color: Colors.black12),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                right: 0,
                height: query.isFilterOpen ? filterHeight : 0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: filterHeight,
                    child: SizedBox(
                      height: filterHeight,
                      child: Material(
                        color: bgColor,
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        child: NotificationListener<ScrollNotification>(
                          // 抽屉内部滚动不应驱动外层 AppBar 的收起/展开。
                          onNotification: (_) => true,
                          child: FilterWidget(
                            type: FilterModule.category,
                            onComplete: completeFilter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final body = isMobile
        ? ScrollAwareToolbarLayout(
            notificationPredicate: (_) => true,
            toolbar: SizedBox(
              height: MobileSearchAppBar.toolbarHeight,
              child: MobileSearchAppBar(
                onSearchTap: () => context.push(AppRoutes.search),
              ),
            ),
            child: categoryContent,
          )
        : categoryContent;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(bottom: false, child: body),
    );
  }
}
