import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/cache_service.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import '../../../data/service/work_repository.dart';
import '../state/work_state.dart';

class WorksNotifier extends AsyncNotifier<WorksState> {
  late final WorkRepository _repository;

  @override
  Future<WorksState> build() async {
    _repository = ref.read(workRepositoryProvider);
    return const WorksState();
  }

  // 通用的安全解析
  /// 热门作品
  Future<void> loadHotWorks({int page = 1}) async {
    try {
      state = const AsyncLoading();
      final result = await _repository.getPopularWorks(page: page);
      final worksJson = result.data?['works'];
      final hotWorks = OtherUtil.parseWorks(worksJson);
      final pagination = result.data?['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? page;
      final hasMore = hotWorks.length < totalCount;
      final prev = state.value ?? const WorksState();
      state = AsyncData(
        prev.copyWith(
          hotWorks: page == 1 ? hotWorks : [...prev.hotWorks, ...hotWorks],
          currentPage: currentPage,
          totalCount: totalCount,
          hasMore: hasMore,
          isLastPage: !hasMore && hotWorks.isNotEmpty,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 推荐作品
  Future<void> loadRecommendedWorks({
    int page = 1,
  }) async {
    try {
      state = const AsyncLoading();
      final recommendUuid = await CacheService.instance.getOrGenerateRecommendUuid();
      final currentUser = await CacheService.instance.getAuthSession();
      final result = await _repository.getRecommendedWorks(
        recommenderUuid: currentUser?.user?.recommenderUuid ?? recommendUuid,
        page: page,
      );
      final worksJson = result.data?['works'];
      final recommendedWorks = OtherUtil.parseWorks(worksJson);
      final pagination = result.data?['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? page;
      final hasMore = recommendedWorks.length < totalCount;

      final prev = state.value ?? const WorksState();

      state = AsyncData(
        prev.copyWith(
          recommendedWorks: page == 1
              ? recommendedWorks
              : [...prev.recommendedWorks, ...recommendedWorks],
          currentPage: currentPage,
          totalCount: totalCount,
          hasMore: hasMore,
          isLastPage: !hasMore && recommendedWorks.isNotEmpty,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadNewWorks({int page = 1}) async {
    try {
      // 首次加载直接 Loading
      if (page == 1) {
        state = const AsyncLoading();
      }
      final result = await _repository.getWorks(
        page: page,
        order: 'release',
      );

      final worksJson = result.data?['works'];
      final newWork = OtherUtil.parseWorks(worksJson);
      final pagination = result.data?['pagination'] as Map<String, dynamic>?;

      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? page;

      final prev = state.value ?? const WorksState();
      final allWorks =
      page == 1 ? newWork : [...prev.newWorks, ...newWork];

      final hasMore = allWorks.length < totalCount;

      state = AsyncData(
        prev.copyWith(
          newWorks: allWorks,
          currentPage: currentPage,
          totalCount: totalCount,
          hasMore: hasMore,
          isLastPage: !hasMore && newWork.isNotEmpty,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  Future<void> loadMoreNewWorks() async {
    final value = state.value;

    // 1. 没有数据 → 不加载更多
    if (value == null) return;

    // 2. 没有更多页 → 不加载
    if (!value.hasMore) return;

    // 加载下一页
    await loadNewWorks(page: value.currentPage + 1);
  }
  /// 刷新（热门 + 推荐并发执行）
  Future<void> refresh() async {
    try {
      state = const AsyncLoading();
      // 2. 刷新并行执行
      await Future.wait([
        loadHotWorks(page: 1),
        loadRecommendedWorks(
          page: 1,
        ),
        loadNewWorks(),
      ]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final worksNotifierProvider =
AsyncNotifierProvider<WorksNotifier, WorksState>(() => WorksNotifier());

