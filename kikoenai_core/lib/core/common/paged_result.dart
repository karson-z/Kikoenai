import 'package:kikoenai_core/core/common/pagination.dart';

/// 通用分页结果容器。
///
/// 用于站点 API 能力接口的强类型返回值，把原始 JSON 响应解析为
/// `List<T>` + [Pagination] 的结构，避免业务层重复手写 fromJson。
///
/// 站点实现负责构造此对象，业务层直接消费 [items] 与 [pagination]。
class PagedResult<T> {
  /// 当前页的数据条目
  final List<T> items;

  /// 分页信息
  final Pagination pagination;

  const PagedResult({
    required this.items,
    required this.pagination,
  });

  /// 是否还有下一页
  bool get hasNextPage =>
      pagination.currentPage * pagination.pageSize < pagination.totalCount;

  /// 当前页条目数
  int get length => items.length;

  /// 是否为空
  bool get isEmpty => items.isEmpty;

  /// 是否非空
  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() =>
      'PagedResult(items: ${items.length}, page: ${pagination.currentPage}/'
      '${(pagination.totalCount + pagination.pageSize - 1) ~/ pagination.pageSize}, '
      'total: ${pagination.totalCount})';
}
