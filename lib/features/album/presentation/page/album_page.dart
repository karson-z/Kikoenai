import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/features/album/presentation/widget/skeleton/skeleton_grid.dart';
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
import '../widget/smart_works_sliver_grid.dart';

class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = context.deviceType;

    return Scaffold(
      appBar: deviceType == DeviceType.mobile
          ? PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: MobileSearchAppBar(
                onSearchTap: () {
                  debugPrint('跳转到搜索页面');
                  context.push(AppRoutes.search);
                },
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(hotWorksProvider.future),
            ref.refresh(recommendedWorksProvider.future),
            ref.refresh(newWorksProvider.future),
          ]);
        },
        child: const CustomScrollView(
          slivers: [
            _HotWorksSection(),
            _RecommendedWorksSection(),
            _NewestWorksSection(),
            SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }
}

class _HotWorksSection extends ConsumerWidget {
  const _HotWorksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotState = ref.watch(hotWorksProvider);

    return SliverMainAxisGroup(
      slivers: [
        SectionHeader(
          title: '热门作品',
          isShowMoreButton: true,
          onMore: () {
            context.push(
              AppRoutes.hotAndRecommend,
              extra: {
                'title': '热门作品',
                'source': WorkDataSource.hot,
              },
            );
          },
        ),
        hotState.when(
          data: (state) => SliverToBoxAdapter(
            child: ResponsiveHorizontalCardList(items: state.works),
          ),
          loading: () => const SliverToBoxAdapter(
            child: ResponsiveHorizontalCardListSkeleton(),
          ),
          error: (error, _) => _SectionErrorSliver(error: error),
        ),
      ],
    );
  }
}

class _RecommendedWorksSection extends ConsumerWidget {
  const _RecommendedWorksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedState = ref.watch(recommendedWorksProvider);

    return SliverMainAxisGroup(
      slivers: [
        SectionHeader(
          title: '推荐作品',
          isShowMoreButton: true,
          onMore: () {
            context.push(
              AppRoutes.hotAndRecommend,
              extra: {
                'title': '推荐作品',
                'source': WorkDataSource.recommended,
              },
            );
          },
        ),
        recommendedState.when(
          data: (state) {
            if (state.works.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: WorkListHorizontal(items: state.works),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: WorkListHorizontalSkeleton(),
          ),
          error: (error, _) => _SectionErrorSliver(error: error),
        ),
      ],
    );
  }
}

class _NewestWorksSection extends ConsumerWidget {
  const _NewestWorksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newestState = ref.watch(newWorksProvider);

    return SliverMainAxisGroup(
      slivers: [
        const SectionHeader(title: '最新作品'),
        newestState.when(
          data: (state) => ResponsiveCardGrid(
            work: state.works,
            hasMore: state.hasMore,
            onLoadMore: () {
              ref.read(newWorksProvider.notifier).loadMore();
            },
          ),
          loading: () => const ResponsiveCardGridSkeleton(),
          error: (error, _) => _SectionErrorSliver(error: error),
        ),
      ],
    );
  }
}

class _SectionErrorSliver extends StatelessWidget {
  final Object error;

  const _SectionErrorSliver({required this.error});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: Center(child: Text('加载失败: $error')),
      ),
    );
  }
}
