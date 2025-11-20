import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/enums/sort_options.dart';
import '../../../../core/widgets/common/collapsible_tab_bar.dart';
import '../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../viewmodel/provider/work_provider.dart';
import '../widget/responsive_horizontal_card_list.dart';
import '../widget/section_header.dart';
import '../widget/work_grid_layout.dart';
import '../widget/work_horizontal.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final collapsePercentNotifier = ValueNotifier<double>(0.0);
  final List<SortOrder> sortOrders = SortOrder.values;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workNotifier = ref.read(worksNotifierProvider.notifier);
      workNotifier.loadNewWorks();
      workNotifier.loadHotWorks();
      workNotifier.loadRecommendedWorks();
    });
  }

  void _handleScroll() {
    final offset = _scrollController.offset.clamp(0, 80);
    collapsePercentNotifier.value = (offset / 80).clamp(0.0, 1.0);

    // 滚动停止后自动吸附
    if (!_scrollController.position.isScrollingNotifier.value) {
      final percent = collapsePercentNotifier.value;
      if (percent > 0.3 && percent < 0.7) {
        final target = percent >= 0.5 ? 80.0 : 0.0;
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
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
    final workNotifier = ref.read(worksNotifierProvider.notifier);

    return DefaultTabController(
      length: sortOrders.length,
      child: Scaffold(
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
                    final order = sortOrders[index];

                    // 点击 Tab 滚动到顶部
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );

                    if (order != sortOrders.first) {
                      workNotifier.changeSortState(order);
                      workNotifier.loadWorks();
                    }
                  },
                ),
              ),
          ],
          body: TabBarView(
            children: sortOrders.map((sortOrder) {
              final isFirst = sortOrder == sortOrders.first;
              return CustomScrollView(
                slivers: [
                  if (isFirst) ..._buildFirstTabExtra(worksState),
                  ..._buildCommonContent(worksState, isFirst),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 第一个 Tab 专属内容
  // ---------------------------------------------------------------------------

  List<Widget> _buildFirstTabExtra(AsyncValue worksState) {
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

  // ---------------------------------------------------------------------------
  // 所有 Tab 共用的内容
  // ---------------------------------------------------------------------------

  List<Widget> _buildCommonContent(AsyncValue worksState, bool isFirst) {
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