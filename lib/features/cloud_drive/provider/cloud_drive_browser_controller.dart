import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../data/cloud_drive_source.dart';
import '../model/cloud_drive_browser_state.dart';
import '../model/cloud_drive_mode.dart';
import 'cloud_drive_source_provider.dart';

typedef CloudDriveBrowserArgs = ({CloudDriveMode mode, String path});

class CloudDriveBrowserController extends Notifier<CloudDriveBrowserState> {
  CloudDriveBrowserController(this.args);

  final CloudDriveBrowserArgs args;
  late CloudDriveSource _source;
  int _browseRequestVersion = 0;
  int _searchRequestVersion = 0;

  static const int _browsePageSize = 50;
  static const int _searchPageSize = 100;

  @override
  CloudDriveBrowserState build() {
    _source = ref.watch(cloudDriveSourceProvider(args.mode));
    return CloudDriveBrowserState(
      usesRemoteSearch: _source.supportsRemoteSearch,
      supportsPagination: _source.supportsPagination,
    );
  }

  Future<void> loadInitial() async {
    final requestVersion = ++_browseRequestVersion;
    state = state.copyWith(
      nodes: const [],
      currentPage: 0,
      totalCount: 0,
      isLoading: true,
      isLoadingMore: false,
      errorMessage: null,
    );

    try {
      final result = await _source.list(
        path: args.path,
        page: 1,
        pageSize: _browsePageSize,
      );
      if (requestVersion != _browseRequestVersion) return;
      state = state.copyWith(
        nodes: result.items,
        currentPage: 1,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (error, stackTrace) {
      if (requestVersion != _browseRequestVersion) return;
      debugPrint('云盘目录加载失败: $error\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _source.describeError(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.isSearchMode && state.usesRemoteSearch) {
      await _loadMoreSearch();
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _source.list(
        path: args.path,
        page: nextPage,
        pageSize: _browsePageSize,
      );
      state = state.copyWith(
        nodes: _appendUnique(state.nodes, result.items),
        currentPage: nextPage,
        totalCount: result.totalCount,
        isLoadingMore: false,
      );
    } catch (error) {
      debugPrint('云盘目录分页加载失败: $error');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      exitSearch();
      return;
    }
    if (!state.usesRemoteSearch) {
      state = state.copyWith(
        isSearchMode: true,
        searchQuery: normalizedQuery,
        searchErrorMessage: null,
      );
      return;
    }

    final requestVersion = ++_searchRequestVersion;
    state = state.copyWith(
      isSearchMode: true,
      searchQuery: normalizedQuery,
      searchNodes: const [],
      searchPage: 0,
      searchTotalCount: 0,
      isSearching: true,
      isSearchingMore: false,
      searchErrorMessage: null,
    );
    try {
      final result = await _source.search(
        path: '/',
        query: normalizedQuery,
        scope: state.scope.apiValue,
        page: 1,
        pageSize: _searchPageSize,
      );
      if (requestVersion != _searchRequestVersion) return;
      state = state.copyWith(
        searchNodes: result.items,
        searchPage: 1,
        searchTotalCount: result.totalCount,
        isSearching: false,
      );
    } catch (error, stackTrace) {
      if (requestVersion != _searchRequestVersion) return;
      debugPrint('云盘搜索失败: $error\n$stackTrace');
      state = state.copyWith(
        isSearching: false,
        searchErrorMessage: _source.describeError(error),
      );
    }
  }

  Future<void> _loadMoreSearch() async {
    if (state.isSearching || state.isSearchingMore || !state.hasMore) return;
    state = state.copyWith(isSearchingMore: true);
    try {
      final nextPage = state.searchPage + 1;
      final result = await _source.search(
        path: '/',
        query: state.searchQuery,
        scope: state.scope.apiValue,
        page: nextPage,
        pageSize: _searchPageSize,
      );
      state = state.copyWith(
        searchNodes: _appendUnique(state.searchNodes, result.items),
        searchPage: nextPage,
        searchTotalCount: result.totalCount,
        isSearchingMore: false,
      );
    } catch (error) {
      debugPrint('云盘搜索分页加载失败: $error');
      state = state.copyWith(isSearchingMore: false);
    }
  }

  void updateLocalSearch(String query) {
    if (state.usesRemoteSearch) {
      if (query.isEmpty) exitSearch();
      return;
    }
    final normalizedQuery = query.trim();
    state = state.copyWith(
      isSearchMode: normalizedQuery.isNotEmpty,
      searchQuery: normalizedQuery,
      searchErrorMessage: null,
    );
  }

  void exitSearch() {
    _searchRequestVersion++;
    state = state.copyWith(
      isSearchMode: false,
      searchQuery: '',
      searchNodes: const [],
      searchPage: 0,
      searchTotalCount: 0,
      isSearching: false,
      isSearchingMore: false,
      searchErrorMessage: null,
    );
  }

  void setScope(CloudDriveScope scope) {
    if (scope == state.scope) return;
    state = state.copyWith(scope: scope);
    if (state.isSearchMode && state.usesRemoteSearch) {
      unawaited(search(state.searchQuery));
    }
  }

  void setSort(CloudDriveSort sort) {
    if (sort != state.sort) state = state.copyWith(sort: sort);
  }

  Future<void> refresh() async {
    if (state.isSearchMode && state.usesRemoteSearch) {
      await search(state.searchQuery);
      return;
    }
    await loadInitial();
  }

  static List<FileNode> _appendUnique(
    List<FileNode> current,
    List<FileNode> incoming,
  ) {
    final keys = current.map(_nodeKey).toSet();
    return [...current, ...incoming.where((node) => keys.add(_nodeKey(node)))];
  }

  static String _nodeKey(FileNode node) =>
      node.remoteId ?? node.path ?? node.mediaStreamUrl ?? node.title;
}

final cloudDriveBrowserControllerProvider = NotifierProvider.autoDispose
    .family<
      CloudDriveBrowserController,
      CloudDriveBrowserState,
      CloudDriveBrowserArgs
    >(CloudDriveBrowserController.new);
