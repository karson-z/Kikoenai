// hot_works_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/state/work_state.dart';
import '../../../../../core/service/cache_service.dart';
import '../../../data/model/work.dart';
import '../../../data/service/work_repository.dart';

class HotWorksNotifier extends AsyncNotifier<WorkState> {
  @override
  Future<WorkState> build() async {
    return _load(page: 1);
  }

  Future<WorkState> _load({required int page}) async {
    final repo = ref.read(workRepositoryProvider);
    final result = await repo.getPopularWorks(page: page);

    // ... 解析逻辑 (OtherUtil.parseWorks 等) ...
    // 这里简化展示
    final works = OtherUtil.parseWorks(result.data?['works']);
    final pagination = result.data?['pagination'];
    final total = pagination?['totalCount'] ?? 0;

    // 如果是第一页直接覆盖，否则追加
    final currentList = (page == 1) ? <Work>[] : (state.value?.works ?? []);

    return WorkState(
      works: [...currentList, ...works],
      currentPage: page,
      totalCount: total,
      hasMore: works.length < total, // 简化的 hasMore 逻辑
    );
  }
  // 加载更多
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading) return;

    state = await AsyncValue.guard(() async {
      return _load(page: currentState.currentPage + 1);
    });
  }
  // 只需要对外暴露刷新方法，内部复用 _load
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1));
  }
}

final hotWorksProvider =
AsyncNotifierProvider.autoDispose<HotWorksNotifier, WorkState>(HotWorksNotifier.new);

// new_works_provider.dart
class NewWorksNotifier extends AsyncNotifier<WorkState> {
  @override
  Future<WorkState> build() async {
    // 初始加载第一页
    return _fetch(page: 1);
  }

  Future<WorkState> _fetch({required int page}) async {
    final repo = ref.read(workRepositoryProvider);
    final result = await repo.getWorks(page: page, order: 'release');

    final newWorks = OtherUtil.parseWorks(result.data?['works']);
    final pagination = result.data?['pagination'];
    final total = pagination?['totalCount'] ?? 0;

    // 获取旧数据
    final oldWorks = state.value?.works ?? [];
    final finalWorks = page == 1 ? newWorks : [...oldWorks, ...newWorks];

    return WorkState(
      works: finalWorks,
      currentPage: page,
      totalCount: total,
      hasMore: finalWorks.length < total,
    );
  }

  // 加载更多
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading) return;

    state = await AsyncValue.guard(() async {
      return _fetch(page: currentState.currentPage + 1);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1));
  }
}

final newWorksProvider =
AsyncNotifierProvider.autoDispose<NewWorksNotifier, WorkState>(NewWorksNotifier.new);
class RecommendedWorksNotifier extends AsyncNotifier<WorkState> {
  @override
  Future<WorkState> build() async {
    // 初始化加载第一页
    return _fetch(page: 1);
  }

  /// 核心加载逻辑
  Future<WorkState> _fetch({required int page}) async {
    final repo = ref.read(workRepositoryProvider);

    // 1. 获取推荐 UUID (保留原逻辑)
    final recommendUuid = await CacheService.instance.getOrGenerateRecommendUuid();
    final currentUser = CacheService.instance.getAuthSession();
    // 优先使用登录用户的 UUID，否则使用设备 UUID
    final targetUuid = currentUser?.user?.recommenderUuid ?? recommendUuid;

    // 2. 发起请求
    final result = await repo.getRecommendedWorks(
      recommenderUuid: targetUuid,
      page: page,
    );

    // 3. 解析数据
    final worksJson = result.data?['works'];
    final newWorks = OtherUtil.parseWorks(worksJson);

    final pagination = result.data?['pagination'];
    final totalCount = pagination?['totalCount'] ?? 0;

    // 4. 合并数据
    final currentWorks = state.value?.works ?? [];
    // 如果是第1页，直接使用新数据；否则追加到旧数据后面
    final finalWorks = page == 1 ? newWorks : [...currentWorks, ...newWorks];

    return WorkState(
      works: finalWorks,
      currentPage: page,
      totalCount: totalCount,
      // 如果当前列表长度小于总数，说明还有更多
      hasMore: finalWorks.length < totalCount,
    );
  }

  /// 加载更多
  Future<void> loadMore() async {
    final currentState = state.value;
    // 卫语句：如果没有数据、没有更多、或者正在加载中，直接返回
    if (currentState == null || !currentState.hasMore || state.isLoading) return;

    // 仅更新数据，不设置 state = AsyncLoading，防止 UI 闪烁
    state = await AsyncValue.guard(() async {
      return _fetch(page: currentState.currentPage + 1);
    });
  }

  /// 刷新 (重置为第一页)
  Future<void> refresh() async {
    // 刷新时显示 Loading 状态
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1));
  }
}

// 定义 Provider
final recommendedWorksProvider =
AsyncNotifierProvider.autoDispose<RecommendedWorksNotifier, WorkState>(
      () => RecommendedWorksNotifier(),
);

// final reviewProvider = FutureProvider((ref) async {
//   final repo = ref.read(workRepositoryProvider);
//   final result = await repo.getReviews();
//   return result)