import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import '../../../../../core/enums/sort_options.dart';
import '../../../../../core/utils/data/other.dart';
import '../../../../../core/model/search_tag.dart';
import '../../../data/service/category_repository.dart';
import '../state/category_data_state.dart';
import '../state/category_ui_state.dart';

// --- CategoryUiNotifier (保持不变，只修改刷新逻辑) ---

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
        localSearchKeyword: "",
      );
    }
  }

  void setLocalSearchKeyword(String val) {
    state = state.copyWith(localSearchKeyword: val);
  }

  void updateKeyword(String? keyword, {bool refreshData = false}) {
    state = state.copyWith(keyword: keyword);
    if (refreshData) {
      _debounceRefresh();
    }
  }

  void searchImmediately() {
    _debounceTimer?.cancel();
    // 修改点 1: 使用 invalidate 使得所有 family provider 失效(重置)
    // 这样当前显示的 Tab 会立即刷新，后台的 Tab 下次划过去时也会刷新
    ref.invalidate(categoryProvider);
  }

  void resetSelected() {
    state = state.copyWith(selected: []);
  }

  // 修改点 2: 这里的 setSort 不再负责触发刷新数据
  // 因为排序现在由 TabBarView 的 index 决定，而不是这个全局状态
  // 这个状态保留仅用于 UI 显示（如高亮当前排序图标）
  void setSort({SortOrder? sortOption, SortDirection? sortDec, bool refreshData = false}) {
    state = state.copyWith(sortOption: sortOption, sortDirection: sortDec);
    // 注意：不再调用 refreshData，因为切换 Tab 时会自动读取对应 provider
  }

  void setSubtitleFilter(int filter, {bool refreshData = false}) {
    state = state.copyWith(subtitleFilter: filter);
    if (refreshData) {
      _debounceRefresh(); // 筛选条件变了，刷新所有
    }
  }

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

  void toggleTag(String type, String name, {bool refreshData = false}) {
    final tags = [...state.selected];
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

    state = state.copyWith(selected: tags);

    if (refreshData) {
      _debounceRefresh();
    }
  }

  String getLoadingMessage(String type) {
    switch (type) {
      case 'tag':
        return "正在获取标签...";
      case 'circle':
        return "正在获取社团...";
      case 'author':
      case 'va':
        return "正在获取声优/作者...";
      case 'age':
        return "正在获取分级信息...";
      default:
        return "正在努力加载中...";
    }
  }

  void _debounceRefresh({Duration duration = const Duration(milliseconds: 800)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      // 修改点 3: 这里的刷新逻辑改为 invalidate
      // 这告诉 Riverpod：“所有分类（Latest, Popular...）的数据都脏了，需要重新获取”
      ref.invalidate(categoryProvider);
    });
  }
}

final categoryUiProvider =
NotifierProvider<CategoryUiNotifier, CategoryUiState>(
        () => CategoryUiNotifier());


// --- CategoryDataNotifier (核心修改：改为 FamilyAsyncNotifier) ---

// 修改点 4: 继承 FamilyAsyncNotifier，并指定参数类型为 SortOrder
class CategoryDataNotifier extends AsyncNotifier<CategoryState> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);
  CategoryDataNotifier(this._currentSortOrder);
  // 保存传入的 sortOrder，以便在 loadMore 中使用
  final SortOrder _currentSortOrder;

  @override
  Future<CategoryState> build() async {
    // 可以在这里 watch uiProvider 的部分状态，实现自动刷新
    // 但为了配合你的手动 debounce 逻辑，这里暂时只做初始化
    return await _load(reset: true);
  }

  Future<CategoryState> _load({required bool reset}) async {
    final ui = ref.read(categoryUiProvider); // 读取全局筛选条件 (Tag, Keyword)
    final prev = state.value ?? const CategoryState();
    final page = reset ? 1 : prev.currentPage + 1;

    var queryParams = SearchTag.buildTagQueryPath(ui.selected, keyword: ui.keyword);

    final result = await _repo.searchWorks(
      page: page,
      // 修改点 5: 使用 family 传入的参数 _currentSortOrder，而不是 ui.sortOption
      order: _currentSortOrder.value,
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

  // 手动刷新方法
  Future<void> refresh() async {
    state = const AsyncLoading();
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

// 修改点 6: 定义 Family Provider
final categoryProvider =
AsyncNotifierProvider.family<CategoryDataNotifier, CategoryState, SortOrder>(CategoryDataNotifier.new);