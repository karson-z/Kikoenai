import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/model/filter_search_state.dart';
import '../../../../../core/enums/sort_options.dart';
import '../../../../../core/model/search_tag.dart';
enum FilterModule {
  category,   // 分类主页
  playlist,   // 播放列表
  global,        // 全局筛选
}
class SearchFilterNotifier extends Notifier<SearchFilterState> {
  // 接收枚举作为唯一标识，完美支持多页面独立复用
  SearchFilterNotifier(this.module);
  final FilterModule module;

  @override
  SearchFilterState build() {
    return const SearchFilterState();
  }

  void toggleFilterDrawer() {
    state = state.copyWith(isFilterOpen: !state.isFilterOpen);
  }

  void closeFilterDrawer() {
    state = state.copyWith(isFilterOpen: false);
  }

  void setFilterIndex(int index) {
    if (state.selectedFilterIndex != index) {
      state = state.copyWith(
        selectedFilterIndex: index,
        localSearchKeyword: "",
      );
    }
  }

  void setLocalSearchKeyword(String val) {
    state = state.copyWith(localSearchKeyword: val);
  }

  void updateKeyword(String? keyword) {
    state = state.copyWith(keyword: keyword);
  }

  void resetSelected() {
    state = state.copyWith(selectedTags: []);
  }

  void setSort({SortOrder? sortOption, SortDirection? sortDec}) {
    state = state.copyWith(
        sortOption: sortOption ?? state.sortOption,
        sortDirection: sortDec ?? state.sortDirection
    );
  }

  void setSubtitleFilter(int filter) {
    state = state.copyWith(subtitleFilter: filter);
  }

  void removeTag(String type, String name) {
    final tags = [...state.selectedTags];
    tags.removeWhere((t) => t.type == type && t.name == name);
    state = state.copyWith(selectedTags: tags);
  }

  void toggleTag(String type, String name) {
    final tags = [...state.selectedTags];
    final idx = tags.indexWhere((t) => t.type == type && t.name == name);

    if (idx == -1) {
      tags.add(SearchTag(type, name, false));
    } else {
      final old = tags[idx];
      if (!old.isExclude) {
        tags[idx] = SearchTag(type, name, true);
      } else {
        tags.removeAt(idx);
      }
    }
    state = state.copyWith(selectedTags: tags);
  }
}

final searchFilterProvider = NotifierProvider.family<SearchFilterNotifier, SearchFilterState, FilterModule>(
  SearchFilterNotifier.new,
);