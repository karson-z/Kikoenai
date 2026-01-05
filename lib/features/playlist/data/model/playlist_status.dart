import 'package:flutter/cupertino.dart';
import 'package:kikoenai/features/playlist/data/model/playlist_request.dart';

@immutable
class PlaylistUiState {
  // --- 核心请求数据 (直接使用你定义的 Request 模型) ---
  final PlaylistWorksRequest request;

  // --- 纯 UI 交互状态 ---
  final bool isFilterOpen;       // 筛选面板是否打开
  final int selectedFilterIndex; // 左侧分类索引 (0:标签, 1:社团...)
  final String localSearchKeyword; // 筛选面板内的本地搜索词

  const PlaylistUiState({
    this.request = const PlaylistWorksRequest(id: ''),
    this.isFilterOpen = false,
    this.selectedFilterIndex = 0,
    this.localSearchKeyword = "",
  });

  PlaylistUiState copyWith({
    PlaylistWorksRequest? request,
    bool? isFilterOpen,
    int? selectedFilterIndex,
    String? localSearchKeyword,
  }) {
    return PlaylistUiState(
      request: request ?? this.request,
      isFilterOpen: isFilterOpen ?? this.isFilterOpen,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      localSearchKeyword: localSearchKeyword ?? this.localSearchKeyword,
    );
  }
}