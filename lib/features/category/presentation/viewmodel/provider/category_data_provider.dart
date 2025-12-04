import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/enums/sort_options.dart';
import '../../../../../core/utils/data/other.dart';
import '../../../data/model/search_tag.dart';
import '../../../data/service/category_repository.dart';
import '../state/category_data_state.dart';
import '../state/category_ui_state.dart';


class CategoryUiNotifier extends Notifier<CategoryUiState> {
  Timer? _debounceTimer;
  @override
  CategoryUiState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const CategoryUiState();
  }

  /// 切换编辑模式
  /// [refreshData] 控制是否在切换编辑状态后刷新数据
  void toggleEditing({bool refreshData = false}) {
    state = state.copyWith(editing: !state.editing);

    if (refreshData) {
      final dataNotifier = ref.read(categoryProvider.notifier);
      dataNotifier.refresh();
    }
  }

  /// 更新关键字
  void updateKeyword(String? keyword, {bool refreshData = false}) {
    state = state.copyWith(keyword: keyword);

    if (refreshData) {
      final dataNotifier = ref.read(categoryProvider.notifier);
      dataNotifier.refresh();
    }
  }

  /// 设置排序选项
  void setSort({SortOrder? sortOption,SortDirection? sortDec,bool refreshData = false}) {
    state = state.copyWith(sortOption: sortOption, sortDirection: sortDec);
    if (refreshData) {
      final dataNotifier = ref.read(categoryProvider.notifier);
      dataNotifier.refresh();
    }
  }
  /// 设置字幕筛选
  void setSubtitleFilter(int filter, {bool refreshData = false}) {
    state = state.copyWith(subtitleFilter: filter);

    if (refreshData) {
      final dataNotifier = ref.read(categoryProvider.notifier);
      dataNotifier.refresh();
    }
  }

  /// 移除选中的标签
  void removeTag(String type, String name, {bool refreshData = false}) {
    final tags = [...state.selected];
    final idx = tags.indexWhere((t) => t.type == type && t.name == name);
    if (idx != -1) {
      tags.removeAt(idx);
      state = state.copyWith(selected: tags);

      if (refreshData) {
        _debounceRefresh();
      }
    }
  }

  void _debounceRefresh({Duration duration = const Duration(milliseconds: 1000)}) {
    _debounceTimer?.cancel(); // 取消上一次
    _debounceTimer = Timer(duration, () {
      final dataNotifier = ref.read(categoryProvider.notifier);
      dataNotifier.refresh();
    });
  }

  /// 切换标签（三态模式或单选模式）
  void toggleTag(String type, String name, {bool refreshData = false}) {
    final tags = [...state.selected];
    final idx = tags.indexWhere((t) => t.type == type && t.name == name);

    if (state.editing) {
      // 三态模式
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
    } else {
      // 单选模式
      tags.removeWhere((t) => t.type == type);
      if (idx == -1) tags.add(SearchTag(type, name, false));
    }

    state = state.copyWith(selected: tags);

    // 如果需要刷新数据
    if(!state.editing){
      if (refreshData) {
        final dataNotifier = ref.read(categoryProvider.notifier);
        dataNotifier.refresh();
      }
    }
  }
}

final categoryUiProvider =
NotifierProvider<CategoryUiNotifier, CategoryUiState>(
        () => CategoryUiNotifier());
class CategoryDataNotifier extends AsyncNotifier<CategoryState> {
  late final CategoryRepository repo;
  @override
  Future<CategoryState> build() async {
    repo = ref.read(categoryRepositoryProvider);
    return await _load(reset: true);
  }

  Future<CategoryState> _load({required bool reset}) async {
    final ui = ref.read(categoryUiProvider);
    final prev = state.value ?? const CategoryState();
    final page = reset ? 1 : prev.currentPage + 1;
    final queryParams = OtherUtil.buildTagQueryPath(ui.selected);
    if(reset) {
      state = AsyncLoading();
    }
    final result = await repo.searchWorks(
      page: page,
      order: ui.sortOption.value,
      sort: ui.sortDirection.value,
      subtitle: ui.subtitleFilter,
      query: queryParams,
    );
    final worksJson = result.data?['works'];
    final newWorks = OtherUtil.parseWorks(worksJson);

    final pagination = result.data?['pagination'];
    final totalCount = pagination?['totalCount'] ?? 0;
    final currentPage = pagination?['currentPage'] ?? page;

    final list = reset ? newWorks : [...prev.works, ...newWorks];

    return prev.copyWith(
      works: list,
      currentPage: currentPage,
      totalCount: totalCount,
      hasMore: list.length < totalCount,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return await _load(reset: true);
    });
  }

  Future<void> loadMore() async {
    try {
      final nextState = await _load(reset: false);
      state = AsyncData(nextState);
    } catch (e, st) {
      // 出错了也要保证 isLoading = false
      state = AsyncError(e, st);
    }
  }
}

final categoryProvider =
AsyncNotifierProvider<CategoryDataNotifier, CategoryState>(
        () => CategoryDataNotifier());
