import 'package:kikoenai_core/kikoenai_core.dart';

import 'cloud_drive_mode.dart';

const _unset = Object();

class CloudDriveBrowserState {
  const CloudDriveBrowserState({
    this.nodes = const [],
    this.currentPage = 0,
    this.totalCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.isSearchMode = false,
    this.searchQuery = '',
    this.searchNodes = const [],
    this.searchPage = 0,
    this.searchTotalCount = 0,
    this.isSearching = false,
    this.isSearchingMore = false,
    this.searchErrorMessage,
    this.scope = CloudDriveScope.all,
    this.sort = CloudDriveSort.defaultSort,
    this.usesRemoteSearch = false,
    this.supportsPagination = false,
  });

  final List<FileNode> nodes;
  final int currentPage;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  final bool isSearchMode;
  final String searchQuery;
  final List<FileNode> searchNodes;
  final int searchPage;
  final int searchTotalCount;
  final bool isSearching;
  final bool isSearchingMore;
  final String? searchErrorMessage;

  final CloudDriveScope scope;
  final CloudDriveSort sort;
  final bool usesRemoteSearch;
  final bool supportsPagination;

  bool get isBusy => isSearchMode ? isSearching : isLoading;
  bool get hasLoadedDirectory => currentPage > 0;
  String? get activeError => isSearchMode ? searchErrorMessage : errorMessage;
  int get activeTotalCount =>
      isSearchMode && usesRemoteSearch ? searchTotalCount : totalCount;
  bool get isLoadingActivePage =>
      isSearchMode ? isSearchingMore : isLoadingMore;

  bool get hasMore {
    if (!supportsPagination) return false;
    if (isSearchMode && usesRemoteSearch) {
      return searchNodes.length < searchTotalCount;
    }
    return !isSearchMode && nodes.length < totalCount;
  }

  List<FileNode> get visibleNodes {
    final source = isSearchMode && usesRemoteSearch ? searchNodes : nodes;
    final normalizedQuery = searchQuery.trim().toLowerCase();
    var result = source
        .where((node) {
          final matchesScope = switch (scope) {
            CloudDriveScope.all => true,
            CloudDriveScope.folders => node.isFolder,
            CloudDriveScope.files => !node.isFolder,
          };
          if (!matchesScope) return false;
          if (!isSearchMode || usesRemoteSearch || normalizedQuery.isEmpty) {
            return true;
          }
          return node.title.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    if (sort == CloudDriveSort.defaultSort) return result;
    result = List<FileNode>.from(result)..sort(_compareNodes);
    return result;
  }

  int _compareNodes(FileNode a, FileNode b) {
    if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
    return switch (sort) {
      CloudDriveSort.nameAsc => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
      CloudDriveSort.nameDesc => b.title.toLowerCase().compareTo(
        a.title.toLowerCase(),
      ),
      CloudDriveSort.sizeAsc => (a.size ?? 0).compareTo(b.size ?? 0),
      CloudDriveSort.sizeDesc => (b.size ?? 0).compareTo(a.size ?? 0),
      CloudDriveSort.modifiedAsc => a.lastModified.compareTo(b.lastModified),
      CloudDriveSort.modifiedDesc => b.lastModified.compareTo(a.lastModified),
      CloudDriveSort.defaultSort => 0,
    };
  }

  CloudDriveBrowserState copyWith({
    List<FileNode>? nodes,
    int? currentPage,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    Object? errorMessage = _unset,
    bool? isSearchMode,
    String? searchQuery,
    List<FileNode>? searchNodes,
    int? searchPage,
    int? searchTotalCount,
    bool? isSearching,
    bool? isSearchingMore,
    Object? searchErrorMessage = _unset,
    CloudDriveScope? scope,
    CloudDriveSort? sort,
    bool? usesRemoteSearch,
    bool? supportsPagination,
  }) {
    return CloudDriveBrowserState(
      nodes: nodes ?? this.nodes,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchNodes: searchNodes ?? this.searchNodes,
      searchPage: searchPage ?? this.searchPage,
      searchTotalCount: searchTotalCount ?? this.searchTotalCount,
      isSearching: isSearching ?? this.isSearching,
      isSearchingMore: isSearchingMore ?? this.isSearchingMore,
      searchErrorMessage: identical(searchErrorMessage, _unset)
          ? this.searchErrorMessage
          : searchErrorMessage as String?,
      scope: scope ?? this.scope,
      sort: sort ?? this.sort,
      usesRemoteSearch: usesRemoteSearch ?? this.usesRemoteSearch,
      supportsPagination: supportsPagination ?? this.supportsPagination,
    );
  }
}
