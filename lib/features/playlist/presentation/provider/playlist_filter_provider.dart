import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/playlist/presentation/provider/playlist_provider.dart';
import '../../../../../../core/enums/sort_options.dart';
import '../../../../../../core/model/search_tag.dart';
import '../../data/model/playlist_status.dart';
class PlaylistNotifier extends Notifier<PlaylistUiState> {
  Timer? _debounceTimer;

  @override
  PlaylistUiState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const PlaylistUiState();
  }

  /// 初始化 ID (进入页面时调用)
  /// 如果你的 state.request.id 为空，必须调用此方法设置
  void initId(String id) {
    if (state.request.id != id) {
      state = state.copyWith(
          request: state.request.copyWith(id: id)
      );
    }
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
        localSearchKeyword: "", // 切换分类时清空本地搜索
      );
    }
  }

  void setLocalSearchKeyword(String val) {
    state = state.copyWith(localSearchKeyword: val);
  }

  // ==========================
  // 数据筛选核心方法 (操作 PlaylistWorksRequest)
  // ==========================

  /// 更新全局搜索关键字 (对应 textKeyword)
  void updateKeyword(String keyword, {bool refreshData = false}) {
    state = state.copyWith(
        request: state.request.copyWith(textKeyword: keyword)
    );

    if (refreshData) {
      _debounceRefresh();
    }
  }

  /// 立即搜索 (取消防抖)
  void searchImmediately() {
    _debounceTimer?.cancel();
    _refreshDataProvider();
  }

  /// 重置所有筛选 (清空 tags)
  void resetSelected() {
    state = state.copyWith(
        request: state.request.copyWith(tags: [])
    );
  }

  /// 设置排序选项
  void setSort({SortOrder? sortOption, SortDirection? sortDec, bool refreshData = false}) {
    // 切换排序时，通常将页码重置为 1
    state = state.copyWith(
        request: state.request.copyWith(
          orderBy: sortOption,
          sort: sortDec,
          page: 1,
        )
    );
    if (refreshData) {
      _refreshDataProvider();
    }
  }

  /// 设置字幕筛选 (对应 subtitlesOnly)
  /// filter: 1 为仅字幕，0 为全部
  void setSubtitleFilter(int filter, {bool refreshData = false}) {
    final bool subtitlesOnly = filter == 1;
    state = state.copyWith(
        request: state.request.copyWith(subtitlesOnly: subtitlesOnly)
    );
    if (refreshData) {
      _refreshDataProvider();
    }
  }

  /// 移除选中的标签
  void removeTag(String type, String name, {bool refreshData = false}) {
    final currentTags = [...state.request.tags];
    final idx = currentTags.indexWhere((t) => t.type == type && t.name == name);

    if (idx != -1) {
      currentTags.removeAt(idx);
      state = state.copyWith(
          request: state.request.copyWith(tags: currentTags)
      );

      // 如果面板是关闭的，移除标签通常希望立即刷新(带防抖)
      if (refreshData && !state.isFilterOpen) {
        _debounceRefresh();
      }
    }
  }

  /// 核心修改：三态切换标签 (筛选 -> 排除 -> 取消)
  void toggleTag(String type, String name, {bool refreshData = false}) {
    final currentTags = [...state.request.tags];
    final idx = currentTags.indexWhere((t) => t.type == type && t.name == name);

    if (idx == -1) {
      // 1. 新增 (Include)
      currentTags.add(SearchTag(type, name, false));
    } else {
      final old = currentTags[idx];
      if (!old.isExclude) {
        // 2. 变成排除 (Exclude)
        currentTags[idx] = SearchTag(type, name, true);
      } else {
        // 3. 移除 (Remove)
        currentTags.removeAt(idx);
      }
    }

    state = state.copyWith(
        request: state.request.copyWith(tags: currentTags)
    );

    if (refreshData) {
      _debounceRefresh();
    }
  }

  // 辅助方法：获取加载文案
  String getLoadingMessage(String type) {
    switch (type) {
      case 'tag': return "正在获取标签...";
      case 'circle': return "正在获取社团...";
      case 'author':
      case 'va': return "正在获取声优/作者...";
      case 'age': return "正在获取分级信息...";
      default: return "正在努力加载中...";
    }
  }

  // ==========================
  // 刷新逻辑
  // ==========================

  void _debounceRefresh({Duration duration = const Duration(milliseconds: 800)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      _refreshDataProvider();
    });
  }

  /// 触发数据 Provider 刷新
  void _refreshDataProvider() {
    final id = state.request.id;
    if (id.isEmpty) return;
    ref.invalidate(playlistWorksProvider(id));
  }
}

// 定义 Provider
final playlistUiProvider = NotifierProvider<PlaylistNotifier, PlaylistUiState>(
  PlaylistNotifier.new,
);