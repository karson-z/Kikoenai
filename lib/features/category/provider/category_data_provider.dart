import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/widgets/pagination/kiko_paging_state.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../../core/service/site/site_api_provider.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../../../../core/widgets/filter/provider/filter_search_notifier.dart';

class CategoryDataNotifier extends AsyncNotifier<KikoPagingState<Work>> {
  CategoryDataNotifier(this.sortOrder);
  final SortOrder sortOrder;
  int _requestVersion = 0;

  SiteApi get _api => ref.read(activeSiteApiProvider);

  /// 计算当前筛选条件的指纹（参与搜索请求的全部条件）
  ///
  /// 用于惰性刷新：切换 tab 时对比数据快照的指纹与当前筛选指纹，
  /// 不一致才重新请求，避免筛选变动时刷新所有存活 tab。
  static String fingerprintOf(SearchFilterState ui) {
    String tagKey(SearchTag t) => '${t.isExclude ? '-' : ''}${t.type}:${t.name}';
    final selected = ui.selectedTags.map(tagKey).toList()..sort();
    final saved =
        AppStorage.filterTagsBox.values.map(tagKey).toList()..sort();
    final nsfw = AppStorage.settingsBox.get(
      StorageKeys.nsfwKey,
      defaultValue: false,
    );
    return [
      'tags=${[...selected, ...saved].join(',')}',
      'kw=${ui.keyword ?? ''}',
      'dir=${ui.sortDirection.name}',
      'sub=${ui.subtitleFilter}',
      'nsfw=$nsfw',
    ].join('|');
  }

  @override
  Future<KikoPagingState<Work>> build() async {
    _requestVersion++;
    ref.watch(activeSiteIdProvider);
    if (!_api.supports(SiteFeature.search)) {
      return KikoPagingState<Work>().appendPage(
        pageKey: 1,
        pageItems: const <Work>[],
        totalCount: 0,
      );
    }
    return _loadPage(pageKey: 1, current: KikoPagingState<Work>());
  }

  Future<KikoPagingState<Work>> _loadPage({
    required int pageKey,
    required KikoPagingState<Work> current,
  }) async {
    final ui = ref.read(searchFilterProvider(FilterModule.category));
    final List<SearchTag> mergedTags = List.from(ui.selectedTags);
    mergedTags.addAll(AppStorage.filterTagsBox.values);
    final isNSFW = AppStorage.settingsBox.get(
      StorageKeys.nsfwKey,
      defaultValue: false,
    );
    if (isNSFW) {
      mergedTags.add(
        SearchTag(TagType.age.stringValue, AgeRatingEnum.all.value, false),
      );
    }

    // 4. 构建包含所有条件(分类特有 + 全局 + SFW + 关键词)的查询字符串
    final queryParams = SearchTag.buildTagQueryPath(
      mergedTags,
      keyword: ui.keyword,
    );

    // 发起网络请求
    final result = await _api.searchWorks(
      SearchWorksRequest(
        page: pageKey,
        order: sortOrder.value, // 使用传入的参数
        sort: ui.sortDirection.value,
        subtitle: ui.subtitleFilter,
        keyword: queryParams,
      ),
    );

    return current.appendPage(
      pageKey: pageKey,
      pageItems: result.items,
      totalCount: result.pagination.totalCount,
      filterFingerprint: fingerprintOf(ui),
    );
  }

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
}

// 暴露 Provider
final categoryProvider = AsyncNotifierProvider.family
    .autoDispose<CategoryDataNotifier, KikoPagingState<Work>, SortOrder>(
      CategoryDataNotifier.new,
    );
