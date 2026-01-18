import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../../../../../core/enums/sort_options.dart';
import '../../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../../../album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../album/presentation/widget/work_grid_layout.dart';
import '../../widget/category_tab_list.dart';
import '../../widget/filter_drawer_panel.dart';
import '../../widget/filter_header_delegate.dart';
import '../../widget/filter_row_panel.dart';
import '../../widget/special_search.dart';
import '../viewmodel/provider/category_data_provider.dart';
import '../viewmodel/provider/category_option_provider.dart';
import '../viewmodel/state/category_ui_state.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final double pinnedHeaderHeight = 90.0;

  @override
  void initState() {
    super.initState();

    final currentSort = ref.read(categoryUiProvider).sortOption;
    int initialIndex = sortOrders.indexOf(currentSort);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: sortOrders.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _autoScrollController = AutoScrollController(axis: Axis.horizontal);

    // --- 修改点 1：Tab 切换监听 ---
    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) { // 只有在滑动结束稳定时才触发
        final order = sortOrders[_tabController.index];

        // 关键修改：refreshData 设为 false！
        // 我们只更新 UI 状态（比如哪个 Tab 高亮），但不强制刷新数据。
        // 数据加载交由 TabView 内部的 KeepAlive 和 Provider 自动处理。
        ref.read(categoryUiProvider.notifier)
            .setSort(sortOption: order, refreshData: false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _autoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(categoryUiProvider);
    final uiNotifier = ref.read(categoryUiProvider.notifier);

    // --- 修改点 2：父页面获取数据 ---
    // 这里依然需要 watch，但目的仅仅是为了获取 totalCount 传给 FilterHeaderDelegate
    // 以及显示当前 Tab 的总数。这不会影响子 Tab 的独立性。
    final currentTabAsync = ref.watch(categoryProvider(uiState.sortOption));
    final totalCount = currentTabAsync.value?.totalCount ?? 0;

    final isMobile = context.isMobile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    // 监听筛选变化以自动滚动 Header
    ref.listen<CategoryUiState>(categoryUiProvider, (previous, next) {
      if (previous != null && next.selected.length > previous.selected.length) {
        final targetIndex = next.selected.length - 1;
        _autoScrollController.scrollToIndex(
          targetIndex,
          preferPosition: AutoScrollPosition.end,
          duration: const Duration(milliseconds: 300),
        );
      }
    });

    // 搜索框回填逻辑
    if (uiState.localSearchKeyword.isEmpty && _searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchController.clear();
      });
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: bgColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            if (isMobile)
              SliverAppBar(
                expandedHeight: 80,
                floating: !uiState.isFilterOpen,
                snap: !uiState.isFilterOpen,
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
                  ref: ref,
                  tabController: _tabController,
                  pinnedHeight: pinnedHeaderHeight,
                  sortOrders: sortOrders,
                  uiState: uiState,
                  uiNotifier: uiNotifier,
                  totalCount: totalCount, // 这里的 Count 依然是动态变化的
                  scrollController: _autoScrollController,
                  buildFilterRow: _buildFilterRowContent,
                ),
              ),
            ),
          ],

          // --- 修改点 3：Body 结构 ---
          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                // 这里不再使用 Builder 也不在 map 里写大段逻辑
                // 而是直接返回封装好的、带 KeepAlive 的组件
                children: sortOrders.map((sortOrder) {
                  return CategoryListTab(
                    key: PageStorageKey<String>(sortOrder.label), // 确保 Key 唯一
                    sortOrder: sortOrder,
                    pinnedHeaderHeight: pinnedHeaderHeight,
                    isFilterOpen: uiState.isFilterOpen,
                  );
                }).toList(),
              ),

              // 筛选遮罩层
              if (uiState.isFilterOpen)
                Positioned.fill(
                  top: pinnedHeaderHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => uiNotifier.toggleFilterDrawer(),
                    child: Container(color: Colors.transparent),
                  ),
                ),

              // 筛选面板
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: pinnedHeaderHeight,
                left: 0,
                right: 0,
                child: FilterDrawerPanel(
                  isOpen: uiState.isFilterOpen,
                  selectedFilterIndex: uiState.selectedFilterIndex,
                  localSearchKeyword: uiState.localSearchKeyword,
                  selectedTags: uiState.selected,
                  tagsAsync: ref.watch(tagsProvider),
                  circlesAsync: ref.watch(circlesProvider),
                  vasAsync: ref.watch(vasProvider),
                  onFilterIndexChanged: (index) => uiNotifier.setFilterIndex(index),
                  onLocalSearchChanged: (val) => uiNotifier.setLocalSearchKeyword(val),
                  onReset: () => uiNotifier.resetSelected(),
                  onApply: () {
                    uiNotifier.toggleFilterDrawer();
                    // 全局刷新：这里使用 invalidate 会重置所有 Tab 的数据
                    // 因为所有 categoryProvider(family) 都会被标记为失效
                    ref.invalidate(categoryProvider);
                  },
                  onToggleTag: (type, name) => uiNotifier.toggleTag(type, name, refreshData: false),
                  getLoadingMessage: (type) => uiNotifier.getLoadingMessage(type),
                  specialFilterBuilder: (context) {
                    return AdvancedFilterPanel(
                      selectedTags: uiState.selected,
                      onToggleTag: (type, name) => uiNotifier.toggleTag(type, name, refreshData: false),
                      fillColor: fillColor,
                      textColor: textColor,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFilterRowContent(
      CategoryUiState uiState,
      CategoryUiNotifier notifier,
      int totalCount,
      Color bgColor,
      Color textColor,
      Color subTextColor,
      Color fillColor,
      Color primaryColor,
      AutoScrollController scrollController) {

    return FilterRowPanel(
      isFilterOpen: uiState.isFilterOpen,
      keyword: uiState.keyword,
      selectedTags: uiState.selected,
      totalCount: totalCount,
      onToggleFilter: () {
        notifier.toggleFilterDrawer();
      },
      onClearKeyword: () {
        notifier.updateKeyword("", refreshData: true);
      },
      onRemoveTag: (tag) {
        notifier.removeTag(tag.type, tag.name, refreshData: true);
      },
      scrollController: scrollController,
      bgColor: bgColor,
      textColor: textColor,
      subTextColor: subTextColor,
      fillColor: fillColor,
      primaryColor: primaryColor,
    );
  }
  List<Widget> _buildCommonContent(
      AsyncValue worksAsync, CategoryDataNotifier controller) {
    return [
      worksAsync.when(
        data: (data) => ResponsiveCardGrid(
          work: data.works,
          hasMore: data.hasMore,
          onLoadMore: () {
            controller.loadMore();
          },
        ),
        // 加载中
        loading: () => const ResponsiveCardGridSkeleton(),
        // 错误
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
              height: 120,
              child: Center(
                  child: Text('加载失败: $e',
                      style: const TextStyle(color: Colors.red)))),
        ),
      ),
    ];
  }
}
