import 'package:flutter/foundation.dart';

const _undefined = Object();

@immutable
class ReviewQueryParams {
  final String order;
  final String sort;
  final int page;

  // 1. 修改类型为 String?
  final String? filter;

  const ReviewQueryParams({
    this.order = 'updated_at',
    this.sort = 'desc',
    this.page = 1,
    this.filter,
  });

  ReviewQueryParams copyWith({
    String? order,
    String? sort,
    int? page,
    Object? filter = _undefined,
  }) {
    return ReviewQueryParams(
      order: order ?? this.order,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      filter: filter == _undefined ? this.filter : (filter as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReviewQueryParams &&
        other.order == order &&
        other.sort == sort &&
        other.page == page &&
        other.filter == filter;
  }

  @override
  int get hashCode {
    return order.hashCode ^
    sort.hashCode ^
    page.hashCode ^
    (filter?.hashCode ?? 0);
  }

  @override
  String toString() => 'ReviewQueryParams(order: $order, sort: $sort, page: $page, filter: $filter)';
}