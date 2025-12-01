import '../../../../../core/enums/sort_options.dart';
import '../../../data/model/search_tag.dart';

class CategoryUiState {
  final bool editing;
  final String? keyword;
  final List<SearchTag> selected;
  final SortOrder sortOption;
  final SortDirection sortDirection;
  final int subtitleFilter; // 0: 全部, 1: 仅字幕

  const CategoryUiState({
    this.editing = false,
    this.keyword,
    this.selected = const [],
    this.sortOption = SortOrder.createDate,
    this.sortDirection = SortDirection.desc,
    this.subtitleFilter = 0,
  });

  CategoryUiState copyWith({
    bool? editing,
    String? keyword,
    List<SearchTag>? selected,
    SortOrder? sortOption,
    SortDirection? sortDirection,
    int? subtitleFilter,
  }) {
    return CategoryUiState(
      editing: editing ?? this.editing,
      keyword: keyword ?? this.keyword,
      selected: selected ?? this.selected,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
    );
  }
}