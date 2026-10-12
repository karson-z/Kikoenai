import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../core/service/site/site_api_provider.dart';

// 定义 Provider
final reviewListProvider =
    AsyncNotifierProvider<ReviewListNotifier, PagedReviewData>(() {
  return ReviewListNotifier();
});

final reviewQueryParamsProvider =
    NotifierProvider<ReviewQueryParamsNotifier, ReviewQueryParams>(
  ReviewQueryParamsNotifier.new,
);

class ReviewQueryParamsNotifier extends Notifier<ReviewQueryParams> {
  @override
  ReviewQueryParams build() => const ReviewQueryParams();

  void update(ReviewQueryParams params) => state = params;
}

class ReviewListNotifier extends AsyncNotifier<PagedReviewData> {
  ReviewQueryParams get _params => ref.read(reviewQueryParamsProvider);

  SiteApi get _api => ref.read(activeSiteApiProvider);

  @override
  Future<PagedReviewData> build() async {
    ref.watch(activeSiteIdProvider);
    if (!_api.supports(SiteFeature.reviews)) {
      return PagedReviewData(
        works: const [],
        pagination: const Pagination(
          currentPage: 1,
          pageSize: 0,
          totalCount: 0,
        ),
      );
    }
    // build 方法只负责加载数据
    return _fetchData();
  }

  /// 内部使用的获取数据逻辑
  Future<PagedReviewData> _fetchData() async {
    // 使用当前的 _params 发起请求，直接返回强类型 PagedResult<Work>
    final result = await _api.fetchReviews(_params);

    return PagedReviewData(works: result.items, pagination: result.pagination);
  }

  // ================= 状态修改方法 =================

  /// 切换页码
  Future<void> setPage(int page) async {
    ref
        .read(reviewQueryParamsProvider.notifier)
        .update(_params.copyWith(page: page));
    // 2. 触发加载 (显示 loading 状态，或者使用 keepPreviousData 保持旧数据)
    state = const AsyncValue.loading();
    // 3. 重新获取数据并更新状态
    state = await AsyncValue.guard(() => _fetchData());
  }

  /// 改变筛选/排序条件 (重置回第 1 页)
  Future<void> updateFilter({
    Object? filter = const Object(), // 使用 Object 标记来区分是否传参
    String? sort,
    String? order,
  }) async {
    // 1. 更新参数逻辑
    var newParams = _params;

    // 处理 filter 的可空逻辑
    if (filter != const Object()) {
      newParams = newParams.copyWith(filter: filter as String?);
    }

    // 更新其他字段并重置页码
    ref.read(reviewQueryParamsProvider.notifier).update(newParams.copyWith(
          sort: sort,
          order: order,
          page: 1, // 改了筛选条件，重置为第一页
        ));

    // 2. 重新加载
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  /// 强制刷新（不改变参数）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}
