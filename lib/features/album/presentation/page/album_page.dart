import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/features/album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/enums/sort_options.dart';
import '../../../../core/routes/app_routes.dart';
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

class _AlbumPageState extends ConsumerState<AlbumPage> with TickerProviderStateMixin {
  final List<SortOrder> sortOrders = SortOrder.values;
  @override
  void initState() {
    super.initState();
    // 仅保留数据加载逻辑
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workNotifier = ref.read(worksNotifierProvider.notifier);
        workNotifier.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = WorkListLayout(
        layoutType: WorkListLayoutType.card)
        .getDeviceType(context);

    final worksState = ref.watch(worksNotifierProvider);

    return Scaffold(
      appBar: deviceType == DeviceType.mobile
          ? PreferredSize(
        preferredSize: const Size.fromHeight(80), // 高度可根据需求调整
        child: MobileSearchAppBar(
          onSearchTap: (){
            debugPrint("跳转到搜索页面");
            context.push(AppRoutes.search);
          },
        ),
      )
          :null,
      body: CustomScrollView(
        slivers: [
          ..._buildFirstTabExtra(worksState),
        ],
      ),
    );
  }

  List<Widget> _buildFirstTabExtra(AsyncValue worksState) {
    // ... 保持不变 ...
    return [
      SectionHeader(title: '热门作品',isShowMoreButton: true, onMore: () {}),

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
      SectionHeader(
        title: '推荐作品',
        isShowMoreButton: true,
        onMore: () {},
      ),
      worksState.when(
        data: (data) {
          // 1. 如果推荐列表为空，则不显示任何内容（包括标题）
          if (data.recommendedWorks.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          // 2. 如果有数据，显示标题 + 列表
          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 将 Header 移入此处
                WorkListHorizontal(items: data.recommendedWorks),
              ],
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          // 加载中通常不需要显示 Header，或者你可以根据设计决定是否把 Header 加进来
          child: WorkListHorizontalSkeleton(),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),
      SectionHeader(title: '最新作品'),
      worksState.when(
        data: (data) =>
            ResponsiveCardGrid(work: data.newWorks,hasMore: data.hasMore,onLoadMore: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(worksNotifierProvider.notifier).loadMoreNewWorks();
              });
            }),
        loading: () => const ResponsiveCardGridSkeleton(),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(height: 120, child: Center(child: Text('加载失败: $e'))),
        ),
      ),
    ];
  }
}