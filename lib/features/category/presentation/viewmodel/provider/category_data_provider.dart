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
  void searchImmediately() {
    _debounceTimer?.cancel();
    ref.read(categoryProvider.notifier).refresh();
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
  String getLoadingMessage(String type) {
    switch (type) {
      case 'tag':     // 请确保这里匹配你传入的 TagType.tag.stringValue
        return "正在获取标签...";
      case 'circle':  // 匹配 TagType.circle.stringValue
        return "正在获取社团...";
      case 'author':  // 匹配 TagType.author.stringValue (或 "va")
      case 'va':
        return "正在获取声优/作者...";
      case 'age':
        return "正在获取分级信息...";
      default:
        return "正在努力加载中...";
    }
  }

  /// 防抖刷新逻辑
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
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  Future<CategoryState> build() async {
    return await _load(reset: true);
  }

  Future<CategoryState> _load({required bool reset}) async {
    final ui = ref.read(categoryUiProvider);
    final prev = state.value ?? const CategoryState();
    final page = reset ? 1 : prev.currentPage + 1;

    final queryParams = OtherUtil.buildTagQueryPath(ui.selected, keyword: ui.keyword);

    // 注意：如果是在 build 初始化期间，不要在这里设置 state = AsyncLoading
    // 只有在手动加载更多时才需要手动控制状态，否则 build 自身的返回就是 loading 态
    if (reset && !state.isLoading) {
      state = const AsyncLoading();
    }
    final result = await _repo.searchWorks(
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

  // 手动刷新方法（对应 UI 中的 refresh 调用）
  Future<void> refresh() async {
    state = const AsyncLoading(); // 先转圈
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