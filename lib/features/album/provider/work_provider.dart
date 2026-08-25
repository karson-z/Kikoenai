import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/widgets/pagination/kiko_paging_state.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../../core/service/cache/cache_service.dart';
import '../../../../../core/service/site/site_api_provider.dart';
import '../../../../../core/storage/hive_key.dart';

abstract class BaseWorksNotifier extends AsyncNotifier<KikoPagingState<Work>> {
  int _requestVersion = 0;

  /// 子类必须实现这个方法，负责调用具体的 API 并返回 PagedResult<Work>
  Future<PagedResult<Work>?> fetchWorksData(int page);

  @override
  Future<KikoPagingState<Work>> build() async {
    _requestVersion++;
    ref.watch(activeSiteIdProvider);
    return _loadPage(pageKey: 1, current: KikoPagingState<Work>());
  }

  /// 公共的 Keyword 构建方法，组装全局标签和特殊限制
  String? buildGlobalKeyword({bool isGet = true}) {
    final tagsToApply = <SearchTag>[];

    // 1. 注入全局筛选标签 (从 Hive 中读取)
    tagsToApply.addAll(AppStorage.filterTagsBox.values);

    // 2. 注入 SFW 限制标签
    final isNSFW = AppStorage.settingsBox.get(
      StorageKeys.nsfwKey,
      defaultValue: false,
    );
    if (isNSFW) {
      tagsToApply.add(
        SearchTag(TagType.age.stringValue, AgeRatingEnum.all.value, false),
      );
    }

    // 3. 构建并返回查询字符串
    if (tagsToApply.isNotEmpty) {
      return SearchTag.buildTagQueryPath(tagsToApply, encode: isGet);
    }

    return null; // 没有标签时返回 null
  }

  /// 核心的通用加载与解析逻辑
  Future<KikoPagingState<Work>> _loadPage({
    required int pageKey,
    required KikoPagingState<Work> current,
  }) async {
    final data = await fetchWorksData(pageKey);
    return current.appendPage(
      pageKey: pageKey,
      pageItems: data?.items ?? const <Work>[],
      totalCount: data?.pagination.totalCount ?? 0,
    );
  }

  /// 加载下一页。追加页错误保存在 PagingState 中，供分页组件展示和重试。
  Future<void> fetchNextPage() async {
    if (state.isLoading) return;
    final current = state.value;
    if (current == null || current.isLoading || !current.hasNextPage) {
      return;
    }

    final requestVersion = ++_requestVersion;
    state = AsyncData(current.copyWith(isLoading: true, error: null));

    try {
      final result = await _loadPage(
        pageKey: current.nextPageKey,
        current: current,
      );
      if (requestVersion == _requestVersion) {
        state = AsyncData(result);
      }
    } catch (error) {
      if (requestVersion == _requestVersion) {
        state = AsyncData(current.copyWith(isLoading: false, error: error));
      }
    }
  }

  /// 通用刷新
  Future<void> refresh() async {
    final requestVersion = ++_requestVersion;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _loadPage(pageKey: 1, current: KikoPagingState<Work>()),
    );
    if (requestVersion == _requestVersion) {
      state = result;
    }
  }
}

// 1. 热门作品
class HotWorksNotifier extends BaseWorksNotifier {
  @override
  Future<PagedResult<Work>?> fetchWorksData(int page) async {
    final keyword = buildGlobalKeyword(isGet: false); // 调用基类方法获取组装好的 keyword
    final api = ref.read(activeSiteApiProvider);
    if (!api.supports(SiteFeature.popular)) return null;
    return api.getPopularWorks(
      SearchWorksRequest(page: page, keyword: keyword),
    );
  }
}

final hotWorksProvider =
    AsyncNotifierProvider.autoDispose<HotWorksNotifier, KikoPagingState<Work>>(
      HotWorksNotifier.new,
    );

// 2. 最新作品
class NewWorksNotifier extends BaseWorksNotifier {
  @override
  Future<PagedResult<Work>?> fetchWorksData(int page) async {
    final keyword = buildGlobalKeyword(); // 调用基类方法获取组装好的 keyword
    final api = ref.read(activeSiteApiProvider);
    if (!api.supports(SiteFeature.search)) return null;
    const order = 'release';
    final sort = SortDirection.desc.value;

    return api.searchWorks(
      SearchWorksRequest(
        page: page,
        keyword: keyword,
        order: order,
        sort: sort,
      ),
    );
  }
}

final newWorksProvider =
    AsyncNotifierProvider.autoDispose<NewWorksNotifier, KikoPagingState<Work>>(
      NewWorksNotifier.new,
    );

// 3. 推荐作品
class RecommendedWorksNotifier extends BaseWorksNotifier {
  @override
  Future<PagedResult<Work>?> fetchWorksData(int page) async {
    final keyword = buildGlobalKeyword(isGet: false); // 调用基类方法获取组装好的 keyword
    final siteId = ref.read(activeSiteIdProvider);
    final api = ref.read(activeSiteApiProvider);
    if (!api.supports(SiteFeature.recommend)) return null;

    final recommendUuid = await CacheService.instance
        .getOrGenerateRecommendUuid(siteId: siteId);
    final currentUser = CacheService.instance.getAuthSession(siteId: siteId);
    final targetUuid = currentUser?.user?.recommenderUuid ?? recommendUuid;

    return api.getRecommendedWorks(
      SearchWorksRequest(
        recommenderUuid: targetUuid,
        page: page,
        keyword: keyword,
      ),
    );
  }
}

final recommendedWorksProvider =
    AsyncNotifierProvider.autoDispose<
      RecommendedWorksNotifier,
      KikoPagingState<Work>
    >(RecommendedWorksNotifier.new);

final albumAllEmptyProvider = Provider<bool>((ref) {
  final hot = ref.watch(hotWorksProvider);
  final recommended = ref.watch(recommendedWorksProvider);
  final newest = ref.watch(newWorksProvider);

  bool isEmpty(AsyncValue<KikoPagingState<Work>> state) {
    if (state.isLoading && !state.hasValue) return false;
    if (state.hasError && !state.hasValue) return false;
    return state.value?.itemList.isEmpty ?? true;
  }

  return isEmpty(hot) && isEmpty(recommended) && isEmpty(newest);
});

typedef SimilarWorkQuery = ({String siteId, String circle});

final similarWorkProvider =
    FutureProvider.family<List<Work>?, SimilarWorkQuery>((
      ref,
      queryParams,
    ) async {
      final api = ref.watch(siteApiByIdProvider(queryParams.siteId));
      if (!api.supports(SiteFeature.search)) return null;
      const order = 'release';
      final sort = SortDirection.desc.value;
      final keyWork = SearchTag(
        TagType.circle.stringValue,
        queryParams.circle,
        true,
      );
      final query = SearchTag.buildTagQueryPath([keyWork], encode: true);
      final result = await api.searchWorks(
        SearchWorksRequest(page: 1, keyword: query, order: order, sort: sort),
      );
      return result.items;
    });
