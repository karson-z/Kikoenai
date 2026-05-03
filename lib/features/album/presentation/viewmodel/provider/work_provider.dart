import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/model/search_tag.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/state/work_state.dart';
import 'package:kikoenai/core/enums/sort_options.dart';
import '../../../../../core/service/cache/cache_service.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../data/service/work_repository.dart';

abstract class BaseWorksNotifier extends AsyncNotifier<WorkState> {
  /// 子类必须实现这个方法，负责调用具体的 API 并返回 result.data
  Future<Map<String, dynamic>?> fetchWorksData(int page);

  @override
  Future<WorkState> build() async {
    return _loadPage(1);
  }

  /// 公共的 Keyword 构建方法，组装全局标签和特殊限制
  String? buildGlobalKeyword({bool isGet = true}) {
    final tagsToApply = <SearchTag>[];

    // 1. 注入全局筛选标签 (从 Hive 中读取)
    tagsToApply.addAll(AppStorage.filterTagsBox.values);

    // 2. 注入 NSFW 限制标签
    final isNSFW = AppStorage.settingsBox.get(StorageKeys.nsfwKey, defaultValue: false);
    if (isNSFW) {
      tagsToApply.add(SearchTag(TagType.age.stringValue, AgeRatingEnum.all.value, false));
    }

    // 3. 构建并返回查询字符串
    if (tagsToApply.isNotEmpty) {
      return SearchTag.buildTagQueryPath(tagsToApply, encode: isGet);
    }

    return null; // 没有标签时返回 null
  }

  /// 核心的通用加载与解析逻辑
  Future<WorkState> _loadPage(int page) async {
    // 1. 调用子类实现的具体网络请求
    final data = await fetchWorksData(page);
    // 2. 统一解析数据
    final newWorks = OtherUtil.parseWorks(data?['works']);
    final total = data?['pagination']?['totalCount'] ?? 0;
    // 3. 统一合并逻辑：第一页覆盖，其他页追加
    final currentWorks = state.value?.works ?? [];
    final finalWorks = page == 1 ? newWorks : [...currentWorks, ...newWorks];

    return WorkState(
      works: finalWorks,
      currentPage: page,
      totalCount: total,
      hasMore: finalWorks.length < total,
    );
  }

  /// 通用加载更多
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading) {
      return;
    }

    state = await AsyncValue.guard(() async {
      return _loadPage(currentState.currentPage + 1);
    });
  }

  /// 通用刷新
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }
}

// 1. 热门作品
class HotWorksNotifier extends BaseWorksNotifier {
  @override
  Future<Map<String, dynamic>?> fetchWorksData(int page) async {
    final keyword = buildGlobalKeyword(isGet: false); // 调用基类方法获取组装好的 keyword
    final repo = ref.read(workRepositoryProvider);
    final result = await repo.getPopularWorks(page: page, keyword: keyword);
    return result.data;
  }
}

final hotWorksProvider =
AsyncNotifierProvider.autoDispose<HotWorksNotifier, WorkState>(
  HotWorksNotifier.new,
);

// 2. 最新作品
class NewWorksNotifier extends BaseWorksNotifier {
  @override
  Future<Map<String, dynamic>?> fetchWorksData(int page) async {
    final keyword = buildGlobalKeyword(); // 调用基类方法获取组装好的 keyword
    final repo = ref.read(workRepositoryProvider);
    const order = 'release';
    final sort = SortDirection.desc.value;

    final result = await repo.getWorks(
        page: page, keyword: keyword, order: order, sort: sort);
    return result.data;
  }
}

final newWorksProvider =
AsyncNotifierProvider.autoDispose<NewWorksNotifier, WorkState>(
  NewWorksNotifier.new,
);

// 3. 推荐作品
class RecommendedWorksNotifier extends BaseWorksNotifier {
  @override
  Future<Map<String, dynamic>?> fetchWorksData(int page) async {
    final keyword = buildGlobalKeyword(isGet: false); // 调用基类方法获取组装好的 keyword
    final repo = ref.read(workRepositoryProvider);

    final recommendUuid =
    await CacheService.instance.getOrGenerateRecommendUuid();
    final currentUser = CacheService.instance.getAuthSession();
    final targetUuid = currentUser?.user?.recommenderUuid ?? recommendUuid;

    final result = await repo.getRecommendedWorks(
        recommenderUuid: targetUuid, page: page, keyword: keyword);
    return result.data;
  }
}

final recommendedWorksProvider =
AsyncNotifierProvider.autoDispose<RecommendedWorksNotifier, WorkState>(
  RecommendedWorksNotifier.new,
);