import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/review_query_params.dart';

class ReviewParamsNotifier extends Notifier<ReviewQueryParams> {

  /// 切换页码
  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  /// 下一页
  void nextPage() {
    state = state.copyWith(page: state.page + 1);
  }

  /// 改变筛选/排序条件
  /// 通常改变这些条件时，我们需要重置回第 1 页
  void updateFilter({String? filter, String? sort, String? order}) {
    state = state.copyWith(
      filter: filter,
      sort: sort,
      order: order,
      page: 1, // 这里的逻辑是：改了筛选条件，就重置回第一页
    );
  }

  /// 重置所有状态
  void reset() {
    state = const ReviewQueryParams();
  }

  @override
  ReviewQueryParams build() {
    return ReviewQueryParams();
  }
}