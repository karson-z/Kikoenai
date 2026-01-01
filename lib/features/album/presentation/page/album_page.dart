import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/features/album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../../config/work_layout_strategy.dart';
import '../../../../core/enums/device_type.dart';
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

class _AlbumPageState extends ConsumerState<AlbumPage> {
  @override
  Widget build(BuildContext context) {
    final deviceType = WorkListLayout(layoutType: WorkListLayoutType.card)
        .getDeviceType(context);

    final hotState = ref.watch(hotWorksProvider);
    final recState = ref.watch(recommendedWorksProvider);
    final newState = ref.watch(newWorksProvider);

    return Scaffold(
      appBar: deviceType == DeviceType.mobile
          ? PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: MobileSearchAppBar(
                onSearchTap: () {
                  debugPrint("跳转到搜索页面");
                  context.push(AppRoutes.search);
                },
              ),
            )
          : null,
      // 添加下拉刷新，同时控制三个 Provider
      body: RefreshIndicator(
        onRefresh: () async {
          // 并行刷新，效率更高
          await Future.wait([
            ref.refresh(hotWorksProvider.future),
            ref.refresh(recommendedWorksProvider.future),
            ref.refresh(newWorksProvider.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // 1. 热门作品区域
            ..._buildHotSection(hotState),

            // 2. 推荐作品区域
            ..._buildRecommendSection(recState),

            // 3. 最新作品区域 (带分页)
            ..._buildNewSection(newState),

            // 底部留白，防止内容贴底
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  // --- 热门作品构建逻辑 ---
  List<Widget> _buildHotSection(AsyncValue hotState) {
    return [
      SectionHeader(
        title: '热门作品',
      ),
      hotState.when(
        data: (state) => SliverToBoxAdapter(
          child: ResponsiveHorizontalCardList(
            items: state.works,
            hasMore: state.hasMore,
            onLoadMore: () {
              ref.read(hotWorksProvider.notifier).loadMore();
            },
          ),
        ),
        loading: () => const SliverToBoxAdapter(
          child: ResponsiveHorizontalCardListSkeleton(),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: Center(child: Text('加载失败: $e')),
          ),
        ),
      ),
    ];
  }

  // --- 推荐作品构建逻辑 ---
  List<Widget> _buildRecommendSection(AsyncValue recState) {
    return [
        SectionHeader(
          title: '推荐作品',
        ),
      recState.when(
        data: (state) {
          if (state.works.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverToBoxAdapter(
            child: WorkListHorizontal(
              items: state.works,
              hasMore: state.hasMore,
              onLoadMore: () {
                ref.read(recommendedWorksProvider.notifier).loadMore();
              },
            ),
          );
        },
        // 加载中显示骨架屏（这里我选择显示骨架屏，你也可以选择隐藏）
        loading: () => const SliverToBoxAdapter(
          child: WorkListHorizontalSkeleton(),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: Center(child: Text('加载失败: $e')),
          ),
        ),
      ),
    ];
  }

  // --- 最新作品构建逻辑 ---
  List<Widget> _buildNewSection(AsyncValue newState) {
    return [
      SectionHeader(title: '最新作品'),
      newState.when(
        data: (state) => ResponsiveCardGrid(
          work: state.works,
          hasMore: state.hasMore,
          onLoadMore: () {
            // 直接调用 newWorksProvider 的 loadMore
            ref.read(newWorksProvider.notifier).loadMore();
          },
        ),
        loading: () => const ResponsiveCardGridSkeleton(),
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: Center(child: Text('加载失败: $e')),
          ),
        ),
      ),
    ];
  }
}
