import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:kikoenai/features/test/provider/subtitles_provider.dart';
import '../state/subtitle_view_state.dart';

// 3. Controller (Notifier)
class SubtitleViewController extends Notifier<SubtitleViewState> {
  @override
  SubtitleViewState build() {
    return const SubtitleViewState();
  }

  // --- 搜索逻辑 ---
  void toggleSearchMode() {
    if (state.isSearchMode) {
      // 关闭搜索时清空查询
      state = state.copyWith(isSearchMode: false, searchQuery: '');
    } else {
      state = state.copyWith(isSearchMode: true);
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // --- 排序逻辑 ---
  void setSortType(SortType type) {
    // 如果点击同一个排序，则切换升降序；否则切换类型并默认升序
    if (state.sortType == type) {
      state = state.copyWith(isAscending: !state.isAscending);
    } else {
      state = state.copyWith(sortType: type, isAscending: true);
    }
  }

  // --- 多选逻辑 ---
  void toggleSelectionMode() {
    if (state.isSelectionMode) {
      // 退出多选模式时清空选中
      state = state.copyWith(isSelectionMode: false, selectedPaths: {});
    } else {
      state = state.copyWith(isSelectionMode: true);
    }
  }

  void toggleFileSelection(String path) {
    final newSet = Set<String>.from(state.selectedPaths);
    if (newSet.contains(path)) {
      newSet.remove(path);
    } else {
      newSet.add(path);
    }
    // 如果取消选中最后一个，是否自动退出多选模式？视需求而定，这里暂不退出
    state = state.copyWith(selectedPaths: newSet);
  }

  void selectAll(List<FileSystemEntity> allFiles) {
    if (state.selectedPaths.length == allFiles.length) {
      state = state.copyWith(selectedPaths: {}); // 全不选
    } else {
      state = state.copyWith(selectedPaths: allFiles.map((e) => e.path).toSet()); // 全选
    }
  }
  void exitModes() {
    state = state.copyWith(
        isSearchMode: false,
        searchQuery: '',
        isSelectionMode: false,
        selectedPaths: {}
    );
  }
}

final subtitleViewProvider = NotifierProvider<SubtitleViewController, SubtitleViewState>(() {
  return SubtitleViewController();
});

// 4. 【核心】派生 Provider：输出经过排序和过滤的列表
// 这样 UI 只需要监听这个 Provider，不需要自己写 sort/filter 逻辑
final filteredFilesProvider = Provider<List<FileSystemEntity>>((ref) {
  // 1. 获取原始数据 (如果还在加载或出错，返回空列表)
  final asyncFiles = ref.watch(directoryContentsProvider);
  final rawFiles = asyncFiles.value ?? [];

  if (rawFiles.isEmpty) return [];

  // 2. 获取视图配置
  final viewState = ref.watch(subtitleViewProvider);

  // 3. 过滤 (Search)
  List<FileSystemEntity> processed = rawFiles;
  if (viewState.searchQuery.isNotEmpty) {
    processed = processed.where((e) =>
        p.basename(e.path).toLowerCase().contains(viewState.searchQuery.toLowerCase())
    ).toList();
  }

  // 4. 排序 (Sort) - 始终保持文件夹在最前
  processed.sort((a, b) {
    final isADir = FileSystemEntity.isDirectorySync(a.path);
    final isBDir = FileSystemEntity.isDirectorySync(b.path);

    if (isADir && !isBDir) return -1;
    if (!isADir && isBDir) return 1;

    int comparison = 0;
    switch (viewState.sortType) {
      case SortType.name:
        comparison = p.basename(a.path).compareTo(p.basename(b.path));
        break;
      case SortType.size:
      // 文件夹大小通常不好计算，视为0或按名字排
        if (isADir) {
          comparison = p.basename(a.path).compareTo(p.basename(b.path));
        } else {
          comparison = (a as File).lengthSync().compareTo((b as File).lengthSync());
        }
        break;
      case SortType.date:
        comparison = a.statSync().modified.compareTo(b.statSync().modified);
        break;
    }

    return viewState.isAscending ? comparison : -comparison;
  });

  return processed;
});