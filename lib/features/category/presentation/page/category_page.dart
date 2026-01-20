import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
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

    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        final order = sortOrders[_tabController.index];
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
    final currentTabAsync = ref.watch(categoryProvider(uiState.sortOption));
    final totalCount = currentTabAsync.value?.totalCount ?? 0;
    final isMobile = context.isMobile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

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
                  totalCount: totalCount,
                  scrollController: _autoScrollController,
                  buildFilterRow: _buildFilterRowContent,
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
                    isFilterOpen: uiState.isFilterOpen,
                  );
                }).toList(),
              ),
              if (currentTabAsync.isRefreshing || currentTabAsync.isLoading)
                Positioned(
                  top: pinnedHeaderHeight, // 避开固定的 Header 区域
                  left: 0,
                  right: 0,
                  child: const LinearProgressIndicator(
                    minHeight: 3.0, // 设置高度：3.0 看起来比较精致，默认是 4.0
                    backgroundColor: Colors.transparent, // 轨道背景透明，只显示移动的进度条
                  ),
                ),

              // 3. 筛选遮罩层
              if (uiState.isFilterOpen)
                Positioned.fill(
                  top: pinnedHeaderHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => uiNotifier.toggleFilterDrawer(),
                    child: Container(color: Colors.transparent),
                  ),
                ),

              // 4. 筛选面板层 (最顶层)
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
}
