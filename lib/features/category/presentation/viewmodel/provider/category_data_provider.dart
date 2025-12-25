import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/enums/sort_options.dart';
import '../../../../../core/utils/data/other.dart';
import '../../../../../core/model/search_tag.dart';
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
        localSearchKeyword: "", // 切换分类时清空搜索
      );
    }
  }
  void setLocalSearchKeyword(String val) {
    state = state.copyWith(localSearchKeyword: val);
  }
  /// 更新关键字
  void updateKeyword(String? keyword, {bool refreshData = false}) {
    state = state.copyWith(keyword: keyword);

    if (refreshData) {
      _debounceRefresh(); // 搜索建议使用防抖
    }
  }
  void resetSelected(){
    state = state.copyWith(selected: []);
  }
  /// 设置排序选项
  void setSort({SortOrder? sortOption, SortDirection? sortDec, bool refreshData = false}) {
    state = state.copyWith(sortOption: sortOption, sortDirection: sortDec);
    if (refreshData) {
      ref.read(categoryProvider.notifier).refresh();
    }
  }

  /// 设置字幕筛选
  void setSubtitleFilter(int filter, {bool refreshData = false}) {
    state = state.copyWith(subtitleFilter: filter);
    if (refreshData) {
      ref.read(categoryProvider.notifier).refresh();
    }
  }

  /// 移除选中的标签
  void removeTag(String type, String name, {bool refreshData = false}) {
    final tags = [...state.selected];
    final idx = tags.indexWhere((t) => t.type == type && t.name == name);
    if (idx != -1) {
      tags.removeAt(idx);
      state = state.copyWith(selected: tags);

      if (refreshData && !state.isFilterOpen) {
        _debounceRefresh();
      }
    }
  }

  /// 核心修改：三态切换标签 (筛选 -> 排除 -> 取消)
  /// 支持多选，点击不同标签不会互斥
  void toggleTag(String type, String name, {bool refreshData = false}) {
    final tags = [...state.selected];
    // 查找是否已存在该标签（无论包含还是排除）
    final idx = tags.indexWhere((t) => t.type == type && t.name == name);

    if (idx == -1) {
      // 状态 1: 未选中 -> 选中 (Include/筛选)
      // isExclude = false
      tags.add(SearchTag(type, name, false));
    } else {
      final old = tags[idx];
      if (!old.isExclude) {
        // 状态 2: 已选中(Include) -> 排除 (Exclude)
        // isExclude = true
        // 保持在原位置修改状态
        tags[idx] = SearchTag(type, name, true);
      } else {
        // 状态 3: 已排除(Exclude) -> 取消 (Remove)
        tags.removeAt(idx);
      }
    }

    // 更新 UI 状态
    state = state.copyWith(selected: tags);

    if (refreshData) {
      _debounceRefresh();
    }
  }

  /// 防抖刷新逻辑
  /// 避免在三态切换过程中（例如用户快速连点两下切换到排除）频繁请求接口
  void _debounceRefresh({Duration duration = const Duration(milliseconds: 800)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      final dataNotifier = ref.read(categoryProvider.notifier);
      dataNotifier.refresh();
    });
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

    // 构建查询参数 (OtherUtil 内部需要支持 isExclude 字段的处理)
    final queryParams = OtherUtil.buildTagQueryPath(ui.selected);

    if (reset) {
      state = const AsyncLoading();
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
    if (state.isLoading) return;
    try {
      final nextState = await _load(reset: false);
      state = AsyncData(nextState);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final categoryProvider =
AsyncNotifierProvider<CategoryDataNotifier, CategoryState>(
        () => CategoryDataNotifier());