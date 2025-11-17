import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/model/work.dart';
import '../../../data/service/work_repository.dart';
import '../state/work_state.dart';

class WorksNotifier extends AsyncNotifier<WorksState> {
  late final WorkRepository _repository;

  @override
  Future<WorksState> build() async {
    // 初始化 repository
    _repository = ref.read(workRepositoryProvider);

    // 直接返回初始状态
    return const WorksState();
  }

  /// 加载热门作品
  Future<void> loadHotWorks({int page = 1}) async {
    state = const AsyncValue.loading();
    final result = await _repository.getPopularWorks(page: page);
    final worksJson = result.data!['works'] as List<dynamic>? ?? [];
    final hotWorks = worksJson.map((e) => Work.fromJson(e)).toList();
    final pagination = result.data!['pagination'] as Map<String, dynamic>?;
    final totalCount = pagination?['totalCount'] as int? ?? 0;
    final currentPage = pagination?['currentPage'] as int? ?? page;
    final hasMore = hotWorks.length >= totalCount;
    // 更新状态
    state = AsyncValue.data(state.value!.copyWith(hotWorks: page == 1 ? hotWorks : [
      ...state.value!.hotWorks,
      ...hotWorks
    ], currentPage: currentPage, totalCount: totalCount, hasMore: hasMore, isLastPage: !hasMore && hotWorks.isNotEmpty
    ));
  }
  /// 加载推荐作品
  Future<void> loadRecommendedWorks({
    required String recommenderUuid,
    int page = 1,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.getRecommendedWorks(
      recommenderUuid: recommenderUuid,
      page: page,
    );
    final worksJson = result.data!['works'] as List<dynamic>? ?? [];
    final recommendedWorks = worksJson.map((e) => Work.fromJson(e)).toList();
    final pagination = result.data!['pagination'] as Map<String, dynamic>?;
    final totalCount = pagination?['totalCount'] as int? ?? 0;
    final currentPage = pagination?['currentPage'] as int? ?? page;
    final hasMore = recommendedWorks.length >= totalCount;
    state = AsyncValue.data(state.value!.copyWith(
        recommendedWorks: page == 1
            ? recommendedWorks
            : [...state.value!.recommendedWorks, ...recommendedWorks],
        currentPage: currentPage,
        totalCount: totalCount,
        hasMore: hasMore,
        isLastPage: !hasMore && recommendedWorks.isNotEmpty
    ));
  }

  /// 刷新全部数据
  Future<void> refresh(String recommenderUuid) async {
    await Future.wait([
      loadHotWorks(page: 1),
      loadRecommendedWorks(recommenderUuid: recommenderUuid, page: 1),
    ]);
  }
}

// provider
final worksNotifierProvider =
AsyncNotifierProvider<WorksNotifier, WorksState>(() => WorksNotifier());
