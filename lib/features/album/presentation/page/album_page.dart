import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/widgets/common/collapsible_tab_bar.dart';
import '../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../viewmodel/provider/work_provider.dart';
import '../widget/responsive_horizontal_card_list.dart';
import '../widget/section_header.dart';
import '../widget/work_grid_layout.dart';
import '../widget/work_horizontal.dart';

enum SortOrder {
  recommend('recommend','推荐'),
  createDate('create_date', '创建日期'),
  release('release', '发布日期'),
  rating('rate_average_2dp', '评分'),
  review('review_count', '评论数'),
  randomSeed('random', '随机'),
  dlCount('dl_count', '销量'),
  price('price', '价格');

  final String value;
  final String label;
  const SortOrder(this.value, this.label);
}

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

    // 初始化 NestedScrollView ScrollController
    _scrollController = ScrollController()
      ..addListener(() {
        // 控制折叠百分比
        final offset = _scrollController.offset.clamp(0, 80);
        collapsePercentNotifier.value = (offset / 80).clamp(0.0, 1.0);
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(worksNotifierProvider.notifier)
          .refresh("172bd570-a894-475b-8a20-9241d0d314e8");
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    collapsePercentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType =
    WorkListLayout(layoutType: WorkListLayoutType.card).getDeviceType(context);
    final worksState = ref.watch(worksNotifierProvider);

    return DefaultTabController(
      length: sortOrders.length,
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxScrolled) => [
            if (deviceType == DeviceType.mobile)
              MobileSearchAppBar(
                collapsePercentNotifier: collapsePercentNotifier,
                bottom: CollapsibleTabBar(
                  collapsePercentNotifier: collapsePercentNotifier,
                  selectedFilter: sortOrders[DefaultTabController.of(context).index].label,
                  filters: sortOrders.map((e) => e.label).toList(),
                  onFilterChanged: (label) {
                    final index = sortOrders.indexWhere((e) => e.label == label);
                    DefaultTabController.of(context).animateTo(index);
                  },
                ),
              ),
          ],
          body: TabBarView(
            children: sortOrders.map((sortOrder) {
              return CustomScrollView(
                slivers: [
                  if (sortOrder == sortOrders.first) ...[
                    SectionHeader(title: '热门作品', onMore: () {}),
                    worksState.when(
                      data: (data) =>
                          SliverToBoxAdapter(child: ResponsiveHorizontalCardList(items: data.hotWorks)),
                      loading: () => const SliverToBoxAdapter(
                        child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                      ),
                      error: (e, _) => SliverToBoxAdapter(
                        child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
                      ),
                    ),
                    SectionHeader(title: '推荐作品', onMore: () {}),
                    worksState.when(
                      data: (data) =>
                          SliverToBoxAdapter(child: WorkListHorizontal(items: data.recommendedWorks)),
                      loading: () => const SliverToBoxAdapter(
                        child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                      ),
                      error: (e, _) => SliverToBoxAdapter(
                        child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
                      ),
                    ),
                  ],
                  SectionHeader(title: '最新作品', onMore: () {}),
                  worksState.when(
                    data: (data) => ResponsiveCardGrid(work: data.works),
                    loading: () => const SliverToBoxAdapter(
                      child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
