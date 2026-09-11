import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/filter/inline/inline_filter.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../widget/category_tab_list.dart';
import '../widget/filter_header.dart';
import '../provider/category_data_provider.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);
  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage>
    with SingleTickerProviderStateMixin {
  final List<SortOrder> sortOrders = SortOrder.values;
  late TabController _tabController;

  /// 筛选即点即生效，但服务端筛选的重刷做防抖，避免连续点击选项时逐次请求
  Timer? _filterRefreshDebounce;
  @override
  void initState() {
    super.initState();
    final currentSort = ref
        .read(searchFilterProvider(FilterModule.category))
        .sortOption;
    int initialIndex = sortOrders.indexOf(currentSort);
    if (initialIndex == -1) initialIndex = 0;
    _tabController = TabController(
      length: sortOrders.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        final order = sortOrders[_tabController.index]; // 切换 Tab 时，同步修改底层的排序状态
        ref
            .read(searchFilterProvider(FilterModule.category).notifier)
            .setSort(sortOption: order); // 惰性刷新：仅当该 tab 缓存数据的筛选指纹与当前筛选不一致时才重新请求
        final ui = ref.read(searchFilterProvider(FilterModule.category));
        final lastFp = ref
            .read(categoryProvider(order))
            .value
            ?.filterFingerprint;
        if (lastFp != null &&
            lastFp != CategoryDataNotifier.fingerprintOf(ui)) {
          ref.invalidate(categoryProvider(order));
        }
      }
    });
  }

  @override
  void dispose() {
    _filterRefreshDebounce?.cancel();
    _tabController.dispose();
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
    final Color bgColor = isDark ? Colors.black : Colors.white;

    // 筛选即点即生效：任一筛选状态变化后，若与缓存数据的指纹不一致则惰性刷新当前 tab
    ref.listen<SearchFilterState>(searchFilterProvider(FilterModule.category), (
      previous,
      next,
    ) {
      if (previous == null) return;
      final cached = ref.read(categoryProvider(next.sortOption));
      final lastFp = cached.value?.filterFingerprint;
      if (lastFp != null &&
          lastFp != CategoryDataNotifier.fingerprintOf(next)) {
        _filterRefreshDebounce?.cancel();
        _filterRefreshDebounce = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          final latest = ref.read(searchFilterProvider(FilterModule.category));
          ref.invalidate(categoryProvider(latest.sortOption));
        });
      }
    });

    final filterHeader = FilterHeader(
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
      filterRow: InlineFilterBar(
        module: FilterModule.category,
        totalCount: totalCount,
        onClearKeyword: () {
          queryNotifier.updateKeyword(null);
          ref.invalidate(categoryProvider(query.sortOption));
        },
      ),
    );
    // 展开面板从 AppBar 底部向下覆盖（盖住收起横条与内容），不压缩页面布局，
    // 内容区以全局模态遮罩拦截交互，点击遮罩收起。
    final categoryContent = Stack(
      children: [
        Column(
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
                ],
              ),
            ),
          ],
        ),
        if (query.isFilterOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: queryNotifier.closeFilterDrawer,
              child: const ColoredBox(color: Colors.black26),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FilterDropdownPanel(
              module: FilterModule.category,
              totalCount: totalCount,
              onClearKeyword: () {
                queryNotifier.updateKeyword(null);
                ref.invalidate(categoryProvider(query.sortOption));
              },
            ),
          ),
        ],
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
