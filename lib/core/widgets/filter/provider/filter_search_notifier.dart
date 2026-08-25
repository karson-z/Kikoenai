import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/core/enums/sort_options.dart';
import 'package:kikoenai_core/core/model/shared/search_tag.dart';
import '../../../storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

enum FilterModule {
  category,   // 分类主页
  playlist,   // 播放列表
  global,     // 全局筛选
  dl,         // DL库（本地已解析作品，仅当前页面使用）
}

class SearchFilterNotifier extends Notifier<SearchFilterState> {
  SearchFilterNotifier(this.module);

  final FilterModule module;

  Box<SearchTag> get filterTagsBox => AppStorage.filterTagsBox;

  @override
  SearchFilterState build() {
    if (module == FilterModule.global) {
      final cachedTags = filterTagsBox.values.toList();
      return const SearchFilterState().copyWith(selectedTags: cachedTags);
    }
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
    if (module == FilterModule.global) {
      filterTagsBox.clear();
    }
    state = state.copyWith(selectedTags: []);
  }
  void resetTagsByType(String type) {
    final tags = [...state.selectedTags];
    tags.removeWhere((t) => t.type == type);

    if (module == FilterModule.global) {
      final keysToDelete = [];
      final map = filterTagsBox.toMap();
      for (final entry in map.entries) {
        if (entry.value.type == type) {
          keysToDelete.add(entry.key);
        }
      }
      if (keysToDelete.isNotEmpty) {
        filterTagsBox.deleteAll(keysToDelete);
      }
    }

    state = state.copyWith(selectedTags: tags);
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

    if (module == FilterModule.global) {
      final key = _findBoxKey(type, name);
      if (key != null) {
        filterTagsBox.delete(key);
      }
    }

    state = state.copyWith(selectedTags: tags);
  }

  void toggleTag(String type, String name) {
    final tags = [...state.selectedTags];
    final idx = tags.indexWhere((t) => t.type == type && t.name == name);

    if (idx == -1) {
      final newTag = SearchTag(type, name, false);
      tags.add(newTag);

      if (module == FilterModule.global) {
        filterTagsBox.add(newTag);
      }
    } else {
      final old = tags[idx];
      if (!old.isExclude) {
        final updatedTag = SearchTag(type, name, true);
        tags[idx] = updatedTag;

        if (module == FilterModule.global) {
          final key = _findBoxKey(type, name);
          if (key != null) {
            filterTagsBox.put(key, updatedTag);
          }
        }
      } else {
        tags.removeAt(idx);

        if (module == FilterModule.global) {
          final key = _findBoxKey(type, name);
          if (key != null) {
            filterTagsBox.delete(key);
          }
        }
      }
    }
    state = state.copyWith(selectedTags: tags);
  }

  // 内部辅助方法：定位 Box 中的唯一 Key
  dynamic _findBoxKey(String type, String name) {
    final map = filterTagsBox.toMap();
    for (final entry in map.entries) {
      final currentTag = entry.value;
      if (currentTag.type == type && currentTag.name == name) {
        return entry.key;
      }
    }
    return null;
  }
}

final searchFilterProvider = NotifierProvider.family<SearchFilterNotifier, SearchFilterState, FilterModule>(
  SearchFilterNotifier.new,
);