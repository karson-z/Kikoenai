import 'package:flutter/cupertino.dart';
import 'package:kikoenai_core/core/model/playlist/playlist_request.dart';

@immutable
class PlaylistUiState {
  // --- Core request data (directly uses the Request model) ---
  final PlaylistWorksRequest request;

  // --- UI interaction state ---
  final bool isFilterOpen;       // Whether the filter panel is open
  final int selectedFilterIndex; // Left side category index (0: tags, 1: circle...)
  final String localSearchKeyword; // Local search keyword in the filter panel

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
