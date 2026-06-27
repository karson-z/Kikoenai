import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/device_type.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../../../../core/widgets/loading/lottie_loading.dart';
import '../viewmodel/provider/work_provider.dart';
import '../widget/responsive_horizontal_card_list.dart';
import '../widget/section_header.dart';
import '../widget/work_grid_layout.dart';
import '../widget/work_horizontal.dart';
import '../widget/smart_works_sliver_grid.dart';

class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = context.deviceType;

    final isEmpty = ref.watch(albumAllEmptyProvider);

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
        child: CustomScrollView(
          slivers: [
            if (isEmpty)
            // 全局空状态占位符
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无任何作品',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const _HotWorksSection(),
              const _RecommendedWorksSection(),
              const _NewestWorksSection(),
            ],
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

    return hotState.when(
      data: (state) {
        if (state.works.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
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
            SliverToBoxAdapter(
              child: ResponsiveHorizontalCardList(items: state.works),
            ),
          ],
        );
      },
      loading: () => const SliverMainAxisGroup(
        slivers: [
          SectionHeader(title: '热门作品', isShowMoreButton: false),
          SliverToBoxAdapter(
            child: _SectionLoadingBox(message: '热门作品加载中...'),
          ),
        ],
      ),
      error: (error, _) => SliverMainAxisGroup(
        slivers: [
          const SectionHeader(title: '热门作品', isShowMoreButton: false),
          _SectionErrorSliver(error: error),
        ],
      ),
    );
  }
}

class _RecommendedWorksSection extends ConsumerWidget {
  const _RecommendedWorksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedState = ref.watch(recommendedWorksProvider);

    return recommendedState.when(
      data: (state) {
        // 如果数据为空，彻底隐藏
        if (state.works.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
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
            SliverToBoxAdapter(
              child: WorkListHorizontal(items: state.works),
            ),
          ],
        );
      },
      loading: () => const SliverMainAxisGroup(
        slivers: [
          SectionHeader(title: '推荐作品', isShowMoreButton: false),
          SliverToBoxAdapter(
            child: _SectionLoadingBox(message: '推荐作品加载中...'),
          ),
        ],
      ),
      error: (error, _) => SliverMainAxisGroup(
        slivers: [
          const SectionHeader(title: '推荐作品', isShowMoreButton: false),
          _SectionErrorSliver(error: error),
        ],
      ),
    );
  }
}

class _NewestWorksSection extends ConsumerWidget {
  const _NewestWorksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newestState = ref.watch(newWorksProvider);

    return newestState.when(
      data: (state) {
        // 如果数据为空，彻底隐藏
        if (state.works.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverMainAxisGroup(
          slivers: [
            const SectionHeader(title: '最新作品'),
            ResponsiveCardGrid(
              work: state.works,
              hasMore: state.hasMore,
              isLoading: state.isLoading,
              onLoadMore: () {
                ref.read(newWorksProvider.notifier).loadMore();
              },
            ),
          ],
        );
      },
      loading: () => const SliverMainAxisGroup(
        slivers: [
          SectionHeader(title: '最新作品'),
          SliverToBoxAdapter(
            child: _SectionLoadingBox(
              message: '最新作品加载中...',
              minHeight: 260,
            ),
          ),
        ],
      ),
      error: (error, _) => SliverMainAxisGroup(
        slivers: [
          const SectionHeader(title: '最新作品'),
          _SectionErrorSliver(error: error),
        ],
      ),
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
        child: Center(
          child: Text(
            '加载失败: $error',
            style: TextStyle(color: Colors.red[300]),
          ),
        ),
      ),
    );
  }
}

class _SectionLoadingBox extends StatelessWidget {
  final String message;
  final double minHeight;

  const _SectionLoadingBox({
    required this.message,
    this.minHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: minHeight,
      child: Center(
        child: LottieLoadingIndicator(
          size: 72,
          message: message,
        ),
      ),
    );
  }
}
