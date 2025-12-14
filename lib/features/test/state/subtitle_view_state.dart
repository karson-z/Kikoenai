enum SortType { name, date, size }

// 2. 定义视图状态
class SubtitleViewState {
  final bool isSearchMode;      // 是否处于搜索模式
  final String searchQuery;     // 搜索关键词
  final SortType sortType;      // 排序类型
  final bool isAscending;       // 是否升序
  final bool isSelectionMode;   // 是否处于多选模式
  final Set<String> selectedPaths; // 已选中的文件路径集合

  const SubtitleViewState({
    this.isSearchMode = false,
    this.searchQuery = '',
    this.sortType = SortType.name,
    this.isAscending = true,
    this.isSelectionMode = false,
    this.selectedPaths = const {},
  });

  SubtitleViewState copyWith({
    bool? isSearchMode,
    String? searchQuery,
    SortType? sortType,
    bool? isAscending,
    bool? isSelectionMode,
    Set<String>? selectedPaths,
  }) {
    return SubtitleViewState(
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      isAscending: isAscending ?? this.isAscending,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedPaths: selectedPaths ?? this.selectedPaths,
    );
  }
}