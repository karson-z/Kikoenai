import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/enums/sort_options.dart';
import '../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../viewmodel/provider/work_provider.dart';
import '../widget/responsive_horizontal_card_list.dart';
import '../widget/section_header.dart';
import '../widget/skeleton/h_card_list_skeleton.dart';
import '../widget/skeleton/work_list_h_skeleton.dart';
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

    // 仅保留数据加载逻辑
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workNotifier = ref.read(worksNotifierProvider.notifier);
        workNotifier.refresh();
    });
  }

  void _handleScroll() {
    final offset = _scrollController.offset.clamp(0, 80);
    collapsePercentNotifier.value = (offset / 80).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    // 移除监听器
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

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, scrolled) => [
          if (deviceType == DeviceType.mobile)
            MobileSearchAppBar(
              collapsePercentNotifier: collapsePercentNotifier,
            ),
        ],
        body: CustomScrollView(
          slivers: [
            ..._buildFirstTabExtra(worksState),
            ..._buildCommonContent(worksState),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFirstTabExtra(AsyncValue worksState) {
    // ... 保持不变 ...
    return [
      SectionHeader(title: '热门作品', onMore: () {}),

      worksState.when(
        data: (data) => SliverToBoxAdapter(
            child: ResponsiveHorizontalCardList(items: data.hotWorks)),
        loading: () => const SliverToBoxAdapter(
          child:
          ResponsiveHorizontalCardListSkeleton(),
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
          WorkListHorizontalSkeleton(),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),

      SectionHeader(title: '最新作品', onMore: () {}),
    ];
  }

  List<Widget> _buildCommonContent(AsyncValue worksState) {
    return [
      worksState.when(
        data: (data) =>
            ResponsiveCardGrid(work: data.newWorks),
        loading: () => const ResponsiveCardGridSkeleton(),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),
    ];
  }
}