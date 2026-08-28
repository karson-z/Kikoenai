import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../data/cloud_drive_source.dart';
import '../model/cloud_drive_mode.dart';
import '../model/cloud_drive_browser_state.dart';
import '../provider/cloud_drive_browser_controller.dart';
import '../provider/cloud_drive_source_provider.dart';
import '../provider/webdav_connection_controller.dart';
import '../widget/cloud_drive_breadcrumb.dart';
import '../widget/cloud_drive_file_details.dart';
import '../widget/cloud_drive_scroll_aware_layout.dart';
import '../widget/cloud_drive_state_content.dart';
import '../widget/cloud_drive_toolbar.dart';

class CloudDriveBrowserPage extends ConsumerStatefulWidget {
  const CloudDriveBrowserPage({
    super.key,
    required this.mode,
    this.initialPath = '/',
    this.rootPath = '/',
    this.isRoot = false,
    this.embedded = false,
    this.onManageSource,
    this.manageTooltip = '来源设置',
  });

  final CloudDriveMode mode;
  final String initialPath;
  final String rootPath;
  final bool isRoot;
  final bool embedded;
  final VoidCallback? onManageSource;
  final String manageTooltip;

  @override
  ConsumerState<CloudDriveBrowserPage> createState() =>
      _CloudDriveBrowserPageState();
}

class _CloudDriveBrowserPageState extends ConsumerState<CloudDriveBrowserPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  static const double _loadMoreThreshold = 240;

  String get _currentPath => _normalizePath(widget.initialPath);
  CloudDriveBrowserArgs get _args => (mode: widget.mode, path: _currentPath);

  List<String> get _pathSegments {
    final rootParts = _pathParts(widget.rootPath);
    final currentParts = _pathParts(_currentPath);
    if (currentParts.length >= rootParts.length &&
        _startsWith(currentParts, rootParts)) {
      return currentParts.skip(rootParts.length).toList(growable: false);
    }
    return currentParts;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(cloudDriveBrowserControllerProvider(_args).notifier)
          .loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreThreshold) {
      return;
    }
    ref.read(cloudDriveBrowserControllerProvider(_args).notifier).loadMore();
  }

  void _enterFolder(FileNode node) {
    final path = node.path;
    if (path == null || path.isEmpty || path == _currentPath) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CloudDriveBrowserPage(
          mode: widget.mode,
          initialPath: path,
          rootPath: widget.rootPath,
          isRoot: false,
        ),
      ),
    );
  }

  void _jumpToSegment(int segmentIndex) {
    final total = _pathSegments.length;
    final popCount = segmentIndex < 0
        ? total
        : (total - segmentIndex - 1).clamp(0, total);
    if (popCount == 0) return;
    var popped = 0;
    Navigator.of(context).popUntil((route) {
      if (popped >= popCount || route.isFirst) return true;
      popped++;
      return false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(cloudDriveBrowserControllerProvider(_args).notifier).exitSearch();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CloudDriveSource>(cloudDriveSourceProvider(widget.mode), (
      previous,
      next,
    ) {
      if (previous == null || identical(previous, next)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(cloudDriveBrowserControllerProvider(_args).notifier)
            .loadInitial();
      });
    });
    final state = ref.watch(cloudDriveBrowserControllerProvider(_args));
    final source = ref.watch(cloudDriveSourceProvider(widget.mode));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = Material(
      color: isDark ? Colors.black : Colors.white,
      child: _buildBrowserBody(state, source.nodeSource),
    );

    return PopScope(
      canPop: !widget.isRoot,
      child: widget.embedded
          ? body
          : Scaffold(
              backgroundColor: isDark ? Colors.black : Colors.white,
              body: SafeArea(bottom: false, child: body),
            ),
    );
  }

  Widget _buildBrowserBody(
    CloudDriveBrowserState state,
    NodeSource nodeSource,
  ) {
    final nodes = state.visibleNodes;
    final error = state.activeError;
    final showLoading = state.isBusy && nodes.isEmpty;
    final showError = error != null && nodes.isEmpty;
    final showEmpty = nodes.isEmpty && !state.isBusy && error == null;
    final controller = ref.read(
      cloudDriveBrowserControllerProvider(_args).notifier,
    );

    return CloudDriveScrollAwareLayout(
      toolbar: CloudDriveToolbar(
        isRoot: widget.isRoot,
        isLoading: state.isBusy,
        usesRemoteSearch: state.usesRemoteSearch,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        scope: state.scope,
        sort: state.sort,
        onBack: () => Navigator.of(context).maybePop(),
        onManageSource: widget.onManageSource,
        manageTooltip: widget.manageTooltip,
        onRefresh: controller.refresh,
        onSearchChanged: (query) {
          controller.updateLocalSearch(query);
        },
        onSearchSubmitted: (query) {
          _searchFocusNode.unfocus();
          controller.search(query);
        },
        onClearSearch: _clearSearch,
        onScopeChanged: controller.setScope,
        onSortChanged: controller.setSort,
      ),
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          key: ValueKey('cloud_drive_${widget.mode.name}_$_currentPath'),
          controller: _scrollController,
          physics: nonBouncingRefreshScrollPhysics,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: CloudDriveBreadcrumbHeaderDelegate(
                segments: _pathSegments,
                onHomeTap: () => _jumpToSegment(-1),
                onSegmentTap: _jumpToSegment,
              ),
            ),
            if (showLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (showError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: CloudDriveErrorContent(
                  message: error,
                  isRoot: widget.isRoot,
                  isSearch: state.isSearchMode,
                  onRetry: controller.refresh,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              )
            else if (showEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: CloudDriveEmptyContent(
                  isSearch: state.isSearchMode,
                  isDirectoryEmpty: state.nodes.isEmpty,
                  onRefresh: controller.refresh,
                ),
              )
            else ...[
              FileNodeBrowser(
                currentNodes: nodes,
                work: null,
                source: nodeSource,
                config: FileBrowserConfig(
                  showDownloadBadge: false,
                  showFolderStatus: false,
                  subtitlesCopyMode: false,
                  enableFolderLongPress: false,
                  enableImagePreview: widget.mode == CloudDriveMode.alistApi,
                  enableTextPreview: widget.mode == CloudDriveMode.alistApi,
                  enableAudioContextMenu: false,
                  showFolderEnterIcon: false,
                  showFileMetaInfo: true,
                ),
                onEnterFolder: _enterFolder,
                onOpenFile: null,
              ),
              SliverToBoxAdapter(
                child: CloudDriveFooter(
                  isLoadingMore: state.isLoadingActivePage,
                  hasMore: state.hasMore,
                  loadedCount: nodes.length,
                  totalCount: state.activeTotalCount,
                  onLoadMore: controller.loadMore,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _normalizePath(String input) =>
      WebDavController.normalizeRemotePath(input);

  static List<String> _pathParts(String input) => _normalizePath(
    input,
  ).split('/').where((part) => part.isNotEmpty).toList(growable: false);

  static bool _startsWith(List<String> value, List<String> prefix) {
    if (prefix.length > value.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (value[i] != prefix[i]) return false;
    }
    return true;
  }
}
