import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/model/work.dart';
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
  List<Work> _parseWorks(dynamic value) {
    if (value is List) {
      return value.map((e) {
        try {
          return Work.fromJson(e);
        } catch (_) {
          return null;
        }
      }).whereType<Work>().toList();
    }
    return [];
  }

  /// 热门作品
  Future<void> loadHotWorks({int page = 1}) async {
    try {
      state = const AsyncLoading();

      final result = await _repository.getPopularWorks(page: page);

      final worksJson = result.data?['works'];
      final hotWorks = _parseWorks(worksJson);

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
    required String recommenderUuid,
    int page = 1,
  }) async {
    try {
      state = const AsyncLoading();

      final result = await _repository.getRecommendedWorks(
        recommenderUuid: recommenderUuid,
        page: page,
      );

      final worksJson = result.data?['works'];
      final recommendedWorks = _parseWorks(worksJson);

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
  Future<void> loadWorks({
    int page = 1,
  }) async {
    try {
      state = const AsyncLoading();

      final result = await _repository.getWorks(
        page: page,
        order: state.value?.sortOption.value,
        subtitle: state.value?.subtitleFilter
      );

      final worksJson = result.data?['works'];
      final work = _parseWorks(worksJson);

      final pagination = result.data?['pagination'] as Map<String, dynamic>?;

      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? page;
      final hasMore = work.length < totalCount;

      final prev = state.value ?? const WorksState();

      state = AsyncData(
        prev.copyWith(
          works: page == 1
              ? work
              : [...prev.works, ...work],
          currentPage: currentPage,
          totalCount: totalCount,
          hasMore: hasMore,
          isLastPage: !hasMore && work.isNotEmpty,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  /// 刷新（热门 + 推荐并发执行）
  Future<void> refresh(String recommenderUuid) async {
    try {
      state = const AsyncLoading();
      await Future.wait([
        loadHotWorks(page: 1),
        loadRecommendedWorks(recommenderUuid: recommenderUuid, page: 1),
        loadWorks(),
      ]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final worksNotifierProvider =
AsyncNotifierProvider<WorksNotifier, WorksState>(() => WorksNotifier());
