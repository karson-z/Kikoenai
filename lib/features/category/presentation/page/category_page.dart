import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../../../../../core/enums/age_rating.dart';
import '../../../../../../../core/enums/sort_options.dart';
import '../../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../../../album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../album/presentation/widget/work_grid_layout.dart';
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
    _tabController = TabController(length: sortOrders.length, vsync: this);
    _autoScrollController = AutoScrollController(
      axis: Axis.horizontal,
    );
    // 监听 Tab 切换，同步排序状态给 Provider
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final order = sortOrders[_tabController.index];
        ref
            .read(categoryUiProvider.notifier)
            .setSort(sortOption: order, refreshData: true);
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
    final worksAsync = ref.watch(categoryProvider);
    final categoryController = ref.read(categoryProvider.notifier);
    final totalCount = worksAsync.value?.totalCount ?? 0;
    final isMobile = context.isMobile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color fillColor =
    isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    ref.listen<CategoryUiState>(categoryUiProvider, (previous, next) {
      if (previous != null && next.selected.length > previous.selected.length) {
        final targetIndex = next.selected.length - 1;
        // 使用 scroll_to_index 的方法
        _autoScrollController.scrollToIndex(
          targetIndex,
          preferPosition: AutoScrollPosition.end,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
    if (uiState.localSearchKeyword.isEmpty &&
        _searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchController.clear();
      });
    }

    return SafeArea(
        child: Scaffold(
      backgroundColor: bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // 1. 搜索栏 (Floating)
          if (isMobile)
            SliverAppBar(
              expandedHeight: 80,
              // 核心修复：面板打开时禁止悬浮，防止遮挡
              floating: !uiState.isFilterOpen,
              snap: !uiState.isFilterOpen,

              backgroundColor: bgColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: MobileSearchAppBar(
                  onSearchTap: () {
                    debugPrint("跳转到搜索页面");
                    context.push(AppRoutes.search);
                  },
                ),
              ),
            ),

          // 2. 排序与筛选栏 (Pinned)
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverPersistentHeader(
              pinned: true,
              delegate: FilterHeaderDelegate(
                ref: ref,
                tabController: _tabController,
                pinnedHeight: pinnedHeaderHeight,
                // 使用更紧凑的高度
                sortOrders: sortOrders,
                uiState: uiState,
                uiNotifier: uiNotifier,
                totalCount: totalCount,
                scrollController: _autoScrollController,
                buildFilterRow: _buildFilterRowContent, // 将你的构建函数传进去
              ),
            ),
          ),
        ],

        // 3. Body
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: sortOrders.map((sortOrder) {
                return Builder(builder: (context) {
                  return RefreshIndicator(
                    edgeOffset: pinnedHeaderHeight,
                    color: primaryColor,
                    backgroundColor: bgColor,
                    onRefresh: () async {
                      // 触发 Provider 刷新
                      return ref.refresh(categoryProvider.future);
                    },
                    notificationPredicate: (notification) {
                      // 确保只响应深度为 0 的滚动（即直接子级 CustomScrollView）
                      return notification.depth == 0;
                    },

                    child: CustomScrollView(
                      key: PageStorageKey<String>(sortOrder.label),

                      physics: uiState.isFilterOpen
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      // 确保包含 AlwaysScrollable

                      slivers: [
                        SliverOverlapInjector(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                        ),
                        ..._buildCommonContent(worksAsync, categoryController),
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 20)),
                      ],
                    ),
                  );
                });
              }).toList(),
            ),
            if (uiState.isFilterOpen)
              Positioned.fill(
                top: pinnedHeaderHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque, // 拦截点击
                  onTap: () => uiNotifier.toggleFilterDrawer(),
                  child: Container(color: Colors.transparent),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: pinnedHeaderHeight,
              left: 0,
              right: 0,
              child: FilterDrawerPanel(
                // --- 状态传递 ---
                isOpen: uiState.isFilterOpen,
                selectedFilterIndex: uiState.selectedFilterIndex,
                localSearchKeyword: uiState.localSearchKeyword,
                selectedTags: uiState.selected,

                // --- 数据传递 (直接传递 Provider 的 watch 结果) ---
                tagsAsync: ref.watch(tagsProvider),
                circlesAsync: ref.watch(circlesProvider),
                vasAsync: ref.watch(vasProvider),

                // --- 业务回调 ---
                onFilterIndexChanged: (index) {
                  uiNotifier.setFilterIndex(index);
                },
                onLocalSearchChanged: (val) {
                  uiNotifier.setLocalSearchKeyword(val);
                },
                onReset: () {
                  uiNotifier.resetSelected();
                },
                onApply: () {
                  uiNotifier.toggleFilterDrawer();
                  ref.read(categoryProvider.notifier).refresh();
                },
                onToggleTag: (type, name) {
                  uiNotifier.toggleTag(type, name, refreshData: false);
                },

                // --- 辅助回调 ---
                getLoadingMessage: (type) => uiNotifier.getLoadingMessage(type),

                // --- 特殊筛选面板构建器 ---
                specialFilterBuilder: (context) {
                  // AdvancedFilterPanel 尚未重构，所以这里还是传 uiState 和 notifier
                  // 如果你也重构了它，这里就传对应参数
                  return AdvancedFilterPanel(
                    // 直接传 uiState 中的 tags
                    selectedTags: uiState.selected,
                    // 直接传 uiNotifier 的方法
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
    ));
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
