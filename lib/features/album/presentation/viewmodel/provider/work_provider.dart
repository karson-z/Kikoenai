import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/sort_options.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/data/json_util.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/user/data/models/user.dart';
import '../../../../../core/storage/hive_key.dart';
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
      // 1. 读取本地用户数据（独立）
      final hive = await HiveStorage.getInstance();
      final rawUserJson = await hive.get(
          BoxNames.user, StorageKeys.currentUser);
      Map<String,dynamic> userJson = JsonUtils.toMap(rawUserJson);
      User? currentUser;
      if (rawUserJson != null) {
        currentUser = User.fromJson(userJson);
      }
      final result = await _repository.getRecommendedWorks(
        recommenderUuid: currentUser?.recommenderUuid ?? "172bd570-a894-475b-8a20-9241d0d314e8",
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

  Future<void> changeSortState({SortOrder? sortOption,SortDirection? sortDec}) async {
    final prev = state.value ?? const WorksState();
    state = AsyncData(prev.copyWith(
      sortOption: sortOption,
      sortDirection: sortDec,
    ));
    loadWorks();
  }

  Future<void> loadWorks({
    int page = 1,
  }) async {
    try {
      state = const AsyncLoading();

      final result = await _repository.getWorks(
          page: page,
          order: state.value?.sortOption.value,
          subtitle: state.value?.subtitleFilter,
          sort: state.value?.sortDirection.value
      );
      debugPrint("sortDecState:${state.value?.sortDirection.value}");
      final worksJson = result.data?['works'];
      final work = OtherUtil.parseWorks(worksJson);
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

  Future<void> loadNewWorks({
    int page = 1,
  }) async {
    try {
      state = const AsyncLoading();

      final result = await _repository.getWorks(
          page: page,
          order: 'release',
      );

      final worksJson = result.data?['works'];
      final newWork = OtherUtil.parseWorks(worksJson);
      final pagination = result.data?['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? page;
      final hasMore = newWork.length < totalCount;
      final prev = state.value ?? const WorksState();

      state = AsyncData(
        prev.copyWith(
          newWorks: page == 1
              ? newWork
              : [...prev.newWorks, ...newWork],
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

