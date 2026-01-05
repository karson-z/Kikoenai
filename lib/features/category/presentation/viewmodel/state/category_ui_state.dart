import '../../../../../core/enums/sort_options.dart';
import '../../../../../core/model/search_tag.dart';

class CategoryUiState {
  final String? keyword; // 搜索的关键词
  final List<SearchTag> selected;
  final SortOrder sortOption;
  final SortDirection sortDirection;
  final int subtitleFilter; // 0: 全部, 1: 仅字幕

  final bool isFilterOpen;       // 筛选面板是否打开
  final int selectedFilterIndex; // 左侧分类索引 (0:标签, 1:社团...)
  final String localSearchKeyword; // 筛选面板内的本地搜索词

  const CategoryUiState({
    this.keyword,
    this.selected = const [],
    this.sortOption = SortOrder.createDate,
    this.sortDirection = SortDirection.desc,
    this.subtitleFilter = 0,
    this.isFilterOpen = false,
    this.selectedFilterIndex = 0,
    this.localSearchKeyword = "",
  });

  CategoryUiState copyWith({
    bool? editing,
    List<SearchTag>? selected,
    SortOrder? sortOption,
    SortDirection? sortDirection,
    int? subtitleFilter,
    String? keyword,
    bool? isFilterOpen,
    int? selectedFilterIndex,
    String? localSearchKeyword,
  }) {
    return CategoryUiState(
      selected: selected ?? this.selected,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
      keyword: keyword ?? this.keyword,
      isFilterOpen: isFilterOpen ?? this.isFilterOpen,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      localSearchKeyword: localSearchKeyword ?? this.localSearchKeyword,
    );
  }
}