import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'search_filter_state.freezed.dart';
// 后面做全局筛选需要持久化
// part 'search_filter_state.g.dart';
// @HiveType(typeId: 1)
///
/// 全局搜索/筛选状态：聚合关键字、已选标签、排序、字幕筛选等。
/// 之后会通过 Hive 持久化，目前以 [SearchFilterState] 形式在 UI 与 sites 两侧共享。
@freezed
abstract class SearchFilterState with _$SearchFilterState {
  const factory SearchFilterState({
    @Default(false) bool isFilterOpen,
    @Default(0) int selectedFilterIndex,
    @Default("") String localSearchKeyword,
    // @HiveField(0)
    String? keyword,
    // @HiveField(1)
    @Default([]) List<SearchTag> selectedTags,
    // @HiveField(2)
    @Default(SortOrder.createDate) SortOrder sortOption,
    // @HiveField(3)
    @Default(SortDirection.desc) SortDirection sortDirection,
    // @HiveField(4)
    @Default(0) int subtitleFilter,
  }) = _SearchFilterState;
}
