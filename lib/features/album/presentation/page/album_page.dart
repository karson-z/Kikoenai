import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/widgets/common/collapsible_tab_bar.dart';

import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/enums/sort_options.dart';
import '../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../viewmodel/provider/work_provider.dart';
import '../widget/responsive_horizontal_card_list.dart';
import '../widget/section_header.dart';
import '../widget/work_grid_layout.dart';
import '../widget/work_horizontal.dart';

// ... 其他导入保持不变 ...

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final collapsePercentNotifier = ValueNotifier<double>(0.0);
  final List<SortOrder> sortOrders = SortOrder.values;

  late final ScrollController _scrollController;
  TabController? _tabController; // 声明 TabController 变量

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(_handleScroll);

    // 仅保留数据加载逻辑
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workNotifier = ref.read(worksNotifierProvider.notifier);
      if (mounted) { // 确保组件仍处于活动状态
        workNotifier.loadNewWorks();
        workNotifier.loadHotWorks();
        workNotifier.loadRecommendedWorks();
      }
    });
  }

  // 处理 Tab 切换和数据加载的逻辑方法 (保持不变)
  void _handleTabSelection() {
    if (_tabController == null || !_tabController!.indexIsChanging) {
      final newIndex = _tabController!.index;
      final order = sortOrders[newIndex];
      final workNotifier = ref.read(worksNotifierProvider.notifier);

      // 滚动重置：折叠 AppBar
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );

      // 数据加载：只有当新的选中 Tab 不是第一个 Tab 时才加载数据
      if (order != sortOrders.first) {
        workNotifier.changeSortState(sortOption: order);
      }
    }
  }

  void _handleScroll() {
    final offset = _scrollController.offset.clamp(0, 80);
    collapsePercentNotifier.value = (offset / 80).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    // 移除监听器
    _tabController?.removeListener(_handleTabSelection);

    _scrollController.dispose();
    collapsePercentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = WorkListLayout(
        layoutType: WorkListLayoutType.card)
        .getDeviceType(context);

    final worksState = ref.watch(worksNotifierProvider);
    // 保持 workNotifier 仅在需要时通过 ref.read() 获取

    return DefaultTabController(
      length: sortOrders.length,
      child: Builder(
        builder: (innerContext) {
          // 在 innerContext 中，DefaultTabController 已经是祖先了，可以安全获取
          final TabController newController = DefaultTabController.of(innerContext);

          if (newController != _tabController) {
            // 先移除旧的监听器 (如果有的话)
            _tabController?.removeListener(_handleTabSelection);

            // 更新并添加新的监听器
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
                  final isFirst = sortOrder == sortOrders.first;
                  return CustomScrollView(
                    key: ValueKey(sortOrder), // 推荐：为 CustomScrollView 添加 Key
                    slivers: [
                      if (isFirst) ..._buildFirstTabExtra(worksState),
                      ..._buildCommonContent(worksState, isFirst),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TabBarView 内部组件 (保持不变)
  // ---------------------------------------------------------------------------

  List<Widget> _buildFirstTabExtra(AsyncValue worksState) {
    // ... 保持不变 ...
    return [
      SectionHeader(title: '热门作品', onMore: () {}),

      worksState.when(
        data: (data) => SliverToBoxAdapter(
            child: ResponsiveHorizontalCardList(items: data.hotWorks)),
        loading: () => const SliverToBoxAdapter(
          child:
          SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),

      SectionHeader(title: '推荐作品', onMore: () {}),

      worksState.when(
        data: (data) => SliverToBoxAdapter(
            child: WorkListHorizontal(items: data.recommendedWorks)),
        loading: () => const SliverToBoxAdapter(
          child:
          SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),

      SectionHeader(title: '最新作品', onMore: () {}),
    ];
  }

  List<Widget> _buildCommonContent(AsyncValue worksState, bool isFirst) {
    // ... 保持不变 ...
    return [
      worksState.when(
        data: (data) =>
            ResponsiveCardGrid(work: isFirst ? data.newWorks : data.works),
        loading: () => const SliverToBoxAdapter(
          child:
          SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),
    ];
  }
}