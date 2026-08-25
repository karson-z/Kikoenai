import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// 应用内分页列表的统一状态。
///
/// 在库提供的 [PagingState] 之上保留接口返回的总数和筛选条件指纹。
@immutable
final class KikoPagingState<ItemType> extends PagingStateBase<int, ItemType> {
  KikoPagingState({
    super.pages,
    super.keys,
    super.error,
    super.hasNextPage,
    super.isLoading,
    this.totalCount = 0,
    this.filterFingerprint = '',
  });

  final int totalCount;
  final String filterFingerprint;

  List<ItemType> get itemList => items ?? List<ItemType>.empty();

  int get nextPageKey => (keys == null || keys!.isEmpty) ? 1 : keys!.last + 1;

  KikoPagingState<ItemType> appendPage({
    required int pageKey,
    required List<ItemType> pageItems,
    required int totalCount,
    String? filterFingerprint,
  }) {
    final loadedCount = itemList.length + pageItems.length;
    return copyWith(
      pages: [...?pages, pageItems],
      keys: [...?keys, pageKey],
      error: null,
      hasNextPage: pageItems.isNotEmpty && loadedCount < totalCount,
      isLoading: false,
      totalCount: totalCount,
      filterFingerprint: filterFingerprint ?? this.filterFingerprint,
    );
  }

  @override
  KikoPagingState<ItemType> copyWith({
    Defaulted<List<List<ItemType>>?>? pages = const Omit(),
    Defaulted<List<int>?>? keys = const Omit(),
    Defaulted<Object?>? error = const Omit(),
    Defaulted<bool>? hasNextPage = const Omit(),
    Defaulted<bool>? isLoading = const Omit(),
    Defaulted<int>? totalCount = const Omit(),
    Defaulted<String>? filterFingerprint = const Omit(),
  }) {
    return KikoPagingState<ItemType>(
      pages: pages is Omit ? this.pages : pages as List<List<ItemType>>?,
      keys: keys is Omit ? this.keys : keys as List<int>?,
      error: error is Omit ? this.error : error as Object?,
      hasNextPage: hasNextPage is Omit ? this.hasNextPage : hasNextPage as bool,
      isLoading: isLoading is Omit ? this.isLoading : isLoading as bool,
      totalCount: totalCount is Omit ? this.totalCount : totalCount as int,
      filterFingerprint: filterFingerprint is Omit
          ? this.filterFingerprint
          : filterFingerprint as String,
    );
  }

  @override
  KikoPagingState<ItemType> reset() => KikoPagingState<ItemType>();

  @override
  bool operator ==(Object other) {
    return other is KikoPagingState<ItemType> &&
        super == other &&
        totalCount == other.totalCount &&
        filterFingerprint == other.filterFingerprint;
  }

  @override
  int get hashCode =>
      Object.hash(super.hashCode, totalCount, filterFingerprint);
}
