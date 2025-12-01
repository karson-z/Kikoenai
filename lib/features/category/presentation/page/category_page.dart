import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/widgets/common/collapsible_tab_bar.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_option_provider.dart';
import '../../../../../../config/work_layout_strategy.dart';
import '../../../../../../core/enums/device_type.dart';
import '../../../../../../core/enums/sort_options.dart';
import '../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../../../album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../album/presentation/widget/work_grid_layout.dart';
import '../widget/category_button_group.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage>
    with TickerProviderStateMixin {
  final collapsePercentNotifier = ValueNotifier<double>(0.0);
  final List<SortOrder> sortOrders = SortOrder.values;
  late final ScrollController _scrollController;
  TabController? _tabController;

  // --- 集中管理 Notifier/Controller 实例 ---
  late final CategoryDataNotifier categoryController;
  late final CategoryUiNotifier categoryUiNotifier;
  // ----------------------------------------

  @override
  void initState() {
    super.initState();

    // 1. 在 initState 中使用 ref.read 获取 Notifier 实例
    categoryController = ref.read(categoryProvider.notifier);
    categoryUiNotifier = ref.read(categoryUiProvider.notifier);

    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset.clamp(0, 80);
    collapsePercentNotifier.value = (offset / 80).clamp(0.0, 1.0);
  }

  void _handleTabSelection() {
    if (_tabController == null || !_tabController!.indexIsChanging) {
      final newIndex = _tabController!.index;
      final order = sortOrders[newIndex];

      // 数据加载：只有当新的选中 Tab 不是第一个 Tab 时才加载数据
      if (order != sortOrders.first) {
        // 直接使用实例
        categoryUiNotifier.setSort(sortOption: order,refreshData: true);
      }
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _scrollController.dispose();
    collapsePercentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- 集中监听 (Watch) ---
    final deviceType = WorkListLayout(layoutType: WorkListLayoutType.card)
        .getDeviceType(context);

    // 监听 FutureProvider (异步数据，用于构建 UI)
    final tagAsync = ref.watch(tagsProvider);
    final circleAsync = ref.watch(circlesProvider);
    final vaAsync = ref.watch(vasProvider);
    const ageRating = AgeRatingEnum.values;
    // 监听 UI 状态和 Work 状态
    final categoryState = ref.watch(categoryUiProvider); // 同步状态
    final worksAsync = ref.watch(categoryProvider);      // 异步工作流状态
    // ----------------------

    // 如果任意数据还在加载或报错，显示对应状态
    return tagAsync.when(
      data: (tags) => circleAsync.when(
        data: (circles) => vaAsync.when(
          data: (vas) {
            return DefaultTabController(
              length: sortOrders.length,
              child: Builder(builder: (innerContext) {
                final TabController newController =
                DefaultTabController.of(innerContext);
                if (newController != _tabController) {
                  _tabController?.removeListener(_handleTabSelection);
                  _tabController = newController;
                  _tabController!.addListener(_handleTabSelection);
                }

                return Scaffold(
                  body: NestedScrollView(
                    controller: _scrollController,
                    headerSliverBuilder: (context, scrolled) => [
                      if (deviceType == DeviceType.mobile)
                        MobileSearchAppBar(
                          collapsePercentNotifier: collapsePercentNotifier,
                          bottom: CollapsibleTabBar(
                            onSortTap: () {
                              final current = categoryState.sortDirection;
                              final next = current == SortDirection.asc
                                  ? SortDirection.desc
                                  : SortDirection.asc;

                              // 直接使用 categoryUiNotifier 实例
                              categoryUiNotifier.setSort(sortDec: next,refreshData: true);
                            },
                            sortDirection: categoryState.sortDirection,
                            collapsePercentNotifier: collapsePercentNotifier,
                            filters: sortOrders.map((e) => e.label).toList(),
                            onTap: (index) {
                              // 只保留点击时的即时动作：滚动到顶部
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                    ],
                    body: TabBarView(
                      children: sortOrders.map((sortOrder) {
                        return NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            final metrics = notification.metrics;

                            if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                              // 直接使用 categoryController 实例
                              categoryController.loadMore();
                            }
                            return false;
                          },
                          child: RefreshIndicator(
                            onRefresh: () async {
                              // 直接使用 categoryController 实例
                              await categoryController.refresh();
                            },
                            child: CustomScrollView(
                              key: ValueKey(sortOrder),
                              slivers: [
                                SliverAppBar(
                                  // Filter Panel 保持不变
                                  pinned: false,
                                  floating: true,
                                  snap: true,
                                  expandedHeight: 190,
                                  backgroundColor: Colors.white,
                                  flexibleSpace: FlexibleSpaceBar(
                                    collapseMode: CollapseMode.pin,
                                    background: Container(
                                      alignment: Alignment.bottomCenter,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      color: Colors.white,
                                      child: EditableCheckGroup(
                                        age: ageRating,
                                        tags: tags,
                                        circles: circles,
                                        vas: vas,
                                        activeColor: Colors.teal,
                                        excludeColor: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                ),
                                // 传入 worksAsync
                                ..._buildCommonContent(worksAsync),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载 VA 失败: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载 Circles 失败: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载 Tags 失败: $e')),
    );
  }

  // 接收 worksAsync (即 AsyncValue<CategoryState>)
  List<Widget> _buildCommonContent(AsyncValue worksAsync) {
    return [
      worksAsync.when(
        data: (data) =>
            ResponsiveCardGrid(work: data.works),
        loading: () => const ResponsiveCardGridSkeleton(),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),
    ];
  }
}
