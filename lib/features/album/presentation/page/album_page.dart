import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/widgets/common/collapsible_tab_bar.dart';
import '../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../viewmodel/provider/work_provider.dart';
import '../widget/section_header.dart';
import '../widget/work_horizontal.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final collapsePercentNotifier = ValueNotifier<double>(0.0);
  String _selectedFilter = '全部';
  final List<String> _filters = ['全部', '最新', '最热', '收藏最多'];

  @override
  void initState() {
    super.initState();

    // 延迟调用 provider 方法，避免在 build/initState 直接修改 provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(worksNotifierProvider.notifier)
          .refresh("172bd570-a894-475b-8a20-9241d0d314e8");
    });
  }

  @override
  void dispose() {
    collapsePercentNotifier.dispose();
    super.dispose();
  }

  void _onFilterChanged(String newFilter) {
    if (newFilter == _selectedFilter) return;
    setState(() {
      _selectedFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceType =
    WorkListLayout(layoutType: WorkListLayoutType.card).getDeviceType(context);

    final worksState = ref.watch(worksNotifierProvider);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.axis == Axis.vertical) {
            final double offset = scroll.metrics.pixels.clamp(0, 80);
            final double percent = (offset / 80).clamp(0.0, 1.0);
            if ((percent - collapsePercentNotifier.value).abs() > 0.01) {
              collapsePercentNotifier.value = percent;
            }
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            // 移动端搜索栏
            if (deviceType == DeviceType.mobile)
              ValueListenableBuilder<double>(
                valueListenable: collapsePercentNotifier,
                builder: (_, collapsePercent, __) {
                  return MobileSearchAppBar(
                    collapsePercent: collapsePercent,
                    collapsePercentNotifier: collapsePercentNotifier,
                    bottom: CollapsibleTabBar(
                      collapsePercentNotifier: collapsePercentNotifier,
                      selectedFilter: _selectedFilter,
                      filters: _filters,
                      onFilterChanged: _onFilterChanged,
                    ),
                  );
                },
              ),

            // 热门作品
            SectionHeader(
              title: '热门作品',
              onMore: () {},
            ),
            worksState.when(
              data: (data) => SliverToBoxAdapter(
                child: WorkListHorizontal(items: data.hotWorks),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(child: Text('加载失败: $e')),
                ),
              ),
            ),

            // 推荐作品
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '推荐作品',
                onMore: () {},
              ),
            ),
            worksState.when(
              data: (data) => SliverToBoxAdapter(
                child: WorkListHorizontal(items: data.recommendedWorks),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(child: Text('加载失败: $e')),
                ),
              ),
            ),

            // 最新作品（静态 mock）
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '最新作品',
                onMore: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
