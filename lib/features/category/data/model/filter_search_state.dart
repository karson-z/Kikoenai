import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../core/enums/sort_options.dart';
import '../../../../../core/model/search_tag.dart';

part 'filter_search_state.freezed.dart';
// 后面做全局筛选需要持久化
// part 'search_filter_state.g.dart';
// @HiveType(typeId: 1)
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