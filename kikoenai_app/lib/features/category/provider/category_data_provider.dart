import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../../core/service/site/site_api_provider.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../../../../core/widgets/filter/provider/filter_search_notifier.dart';

class CategoryDataNotifier extends AsyncNotifier<FilterDataState> {
  CategoryDataNotifier(this.sortOrder);
  final SortOrder sortOrder;

  SiteApi get _api => ref.read(activeSiteApiProvider);

  @override
  Future<FilterDataState> build() async {
    ref.watch(activeSiteIdProvider);
    if (!_api.supports(SiteFeature.search)) {
      return const FilterDataState();
    }
    return await _load(reset: true);
  }

  Future<FilterDataState> _load({required bool reset}) async {
    final ui = ref.read(searchFilterProvider(FilterModule.category));
    final prev = state.value ?? const FilterDataState();
    final page = reset ? 1 : prev.currentPage + 1;
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

    // 4. 构建包含所有条件(分类特有 + 全局 + NSFW + 关键词)的查询字符串
    var queryParams = SearchTag.buildTagQueryPath(
      mergedTags,
      keyword: ui.keyword,
    );

    // 发起网络请求
    final result = await _api.searchWorks(
      SearchWorksRequest(
        page: page,
        order: sortOrder.value, // 使用传入的参数
        sort: ui.sortDirection.value,
        subtitle: ui.subtitleFilter,
        keyword: queryParams,
      ),
    );

    final newWorks = result.items;
    final totalCount = result.pagination.totalCount;
    final currentPage = result.pagination.currentPage;
    final list = reset ? newWorks : [...prev.works, ...newWorks];

    return prev.copyWith(
      works: list,
      currentPage: currentPage,
      totalCount: totalCount,
      hasMore: list.length < totalCount,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }

    // 开始加载
    state = AsyncData(current.copyWith(isLoading: true));

    try {
      final result = await _load(reset: false);

      state = AsyncData(result.copyWith(isLoading: false));
    } catch (e, st) {
      state = AsyncData(current.copyWith(isLoading: false));
      Error.throwWithStackTrace(e, st);
    }
  }
}

// 暴露 Provider
final categoryProvider = AsyncNotifierProvider.family
    .autoDispose<CategoryDataNotifier, FilterDataState, SortOrder>(
      CategoryDataNotifier.new,
    );
