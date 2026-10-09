import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/file_browser/model/file_browser_edit_config.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_notifier.dart';
import 'package:kikoenai/features/file_browser/widget/cloud_playable_progress_dialog.dart';
import 'package:kikoenai/features/file_browser/widget/file_browser_edit_bar.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../data/cloud_drive_source.dart';
import '../model/cloud_drive_mode.dart';
import '../model/cloud_drive_browser_state.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import '../provider/cloud_drive_browser_controller.dart';
import '../provider/cloud_drive_source_provider.dart';
import '../provider/webdav_connection_controller.dart';
import '../widget/cloud_drive_breadcrumb.dart';
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
  final Map<String, double> _scrollOffsets = {};
  late String _currentPath;
  bool _isChangingPath = false;
  Object? _directoryKey;

  static const double _loadMoreThreshold = 240;

  CloudDriveBrowserArgs get _args => (mode: widget.mode, path: _currentPath);
  bool get _isAtRoot => _currentPath == _normalizePath(widget.rootPath);

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
    _currentPath = _normalizePath(widget.initialPath);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(cloudDriveBrowserControllerProvider(_args).notifier)
          .loadIfNeeded();
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
    _navigateToPath(path);
  }

  void _jumpToSegment(int segmentIndex) {
    final rootParts = _pathParts(widget.rootPath);
    final targetParts = segmentIndex < 0
        ? rootParts
        : [...rootParts, ..._pathSegments.take(segmentIndex + 1)];
    _navigateToPath('/${targetParts.join('/')}');
  }

  void _navigateBack() {
    if (_isAtRoot) {
      Navigator.of(context).maybePop();
      return;
    }
    _jumpToSegment(_pathSegments.length - 2);
  }

  void _navigateToPath(String path) {
    final nextPath = _normalizePath(path);
    if (nextPath == _currentPath) return;

    final currentArgs = _args;
    final currentState = ref.read(
      cloudDriveBrowserControllerProvider(currentArgs),
    );
    if (currentState.isSearchMode) {
      ref
          .read(cloudDriveBrowserControllerProvider(currentArgs).notifier)
          .exitSearch();
    }
    _rememberScrollOffset();

    final nextArgs = (mode: widget.mode, path: nextPath);
    final hasCachedState = ref
        .read(cloudDriveBrowserControllerProvider(nextArgs))
        .hasLoadedDirectory;
    _searchFocusNode.unfocus();
    _searchController.clear();

    setState(() {
      _currentPath = nextPath;
      _isChangingPath = !hasCachedState;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _currentPath != nextPath) return;
      await ref
          .read(cloudDriveBrowserControllerProvider(nextArgs).notifier)
          .loadIfNeeded();
      if (!mounted || _currentPath != nextPath) return;
      if (_isChangingPath) setState(() => _isChangingPath = false);
      _restoreScrollOffset(nextPath);
    });
  }

  void _rememberScrollOffset() {
    if (!_scrollController.hasClients) return;
    _scrollOffsets[_currentPath] = _scrollController.offset;
  }

  void _restoreScrollOffset(String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentPath != path || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final savedOffset = _scrollOffsets[path] ?? position.minScrollExtent;
      _scrollController.jumpTo(
        savedOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
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
      _scrollOffsets.clear();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
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
    final editing = ref.watch(cloudFileEditProvider).isEditing;
    final body = Material(
      color: isDark ? Colors.black : Colors.white,
      child: Column(
        children: [
          Expanded(child: _buildBrowserBody(state, source.nodeSource)),
          if (editing) _buildEditBar(state),
        ],
      ),
    );

    return PopScope(
      canPop: _isAtRoot && !widget.isRoot,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop || _isAtRoot) return;
        _navigateBack();
      },
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
    final directoryKey = Object.hash(
      widget.mode,
      _currentPath,
      state.isSearchMode,
      state.searchQuery,
      state.scope,
    );
    if (_directoryKey != directoryKey) {
      _directoryKey = directoryKey;
      final visibleKeys = nodes.map((node) => node.keyId).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _directoryKey != directoryKey) return;
        ref.read(cloudFileEditProvider.notifier).retainVisible(visibleKeys);
      });
    }
    final edit = ref.watch(cloudFileEditProvider);
    final error = state.activeError;
    final showLoading = (_isChangingPath || state.isBusy) && nodes.isEmpty;
    final showError = error != null && nodes.isEmpty;
    final showEmpty = nodes.isEmpty && !state.isBusy && error == null;
    final controller = ref.read(
      cloudDriveBrowserControllerProvider(_args).notifier,
    );

    return CloudDriveScrollAwareLayout(
      toolbar: CloudDriveToolbar(
        isRoot: _isAtRoot,
        isLoading: state.isBusy,
        usesRemoteSearch: state.usesRemoteSearch,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        scope: state.scope,
        sort: state.sort,
        onBack: _navigateBack,
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
                  isRoot: _isAtRoot,
                  isSearch: state.isSearchMode,
                  onRetry: controller.refresh,
                  onBack: _navigateBack,
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
                  showFolderStatus: true,
                  subtitlesCopyMode: false,
                  enableImagePreview: widget.mode == CloudDriveMode.alistApi,
                  enableTextPreview: widget.mode == CloudDriveMode.alistApi,
                  enableAudioContextMenu: false,
                  showFolderEnterIcon: false,
                  showFileMetaInfo: true,
                ),
                onEnterFolder: _enterFolder,
                onOpenFile: null,
                editConfig: FileBrowserEditConfig(
                  isEditing: edit.isEditing,
                  selectedKeys: edit.selectedKeys,
                  onToggle: (keyId) =>
                      ref.read(cloudFileEditProvider.notifier).toggle(keyId),
                  onRequestEdit: (keyId) =>
                      ref.read(cloudFileEditProvider.notifier).enter(keyId),
                ),
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

  Widget _buildEditBar(CloudDriveBrowserState state) {
    final edit = ref.watch(cloudFileEditProvider);
    final visible = state.visibleNodes;
    final selected = visible
        .where((node) => edit.selectedKeys.contains(node.keyId))
        .toList(growable: false);
    final parsed = ref.watch(parsedWorkIdsProvider);
    final queue = ref.watch(scraperQueueProvider);
    final canParse = FileBrowserEditActions.parseCandidates(
      directoryNodes: selected,
      parsedWorkIds: parsed,
      queue: queue,
    ).isNotEmpty;
    return FileBrowserEditBar(
      selectedCount: selected.length,
      allSelected: edit.allVisibleSelected(visible.map((node) => node.keyId)),
      canParse: canParse,
      canPlay: selected.isNotEmpty,
      canExclude: false,
      onToggleAll: () => ref
          .read(cloudFileEditProvider.notifier)
          .toggleVisibleSelection(visible.map((node) => node.keyId)),
      onParse: () => _parseSelected(selected, parsed, queue),
      onPlay: () => _playSelected(selected),
      onExclude: () {},
      onDone: () => ref.read(cloudFileEditProvider.notifier).exit(),
    );
  }

  Future<void> _parseSelected(
    List<FileNode> selected,
    Set<int> parsed,
    ScraperQueueState queue,
  ) async {
    final candidates = FileBrowserEditActions.parseCandidates(
      directoryNodes: selected,
      parsedWorkIds: parsed,
      queue: queue,
    );
    if (candidates.isEmpty) return;
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '加入解析队列',
      content: '将 ${candidates.length} 个作品文件夹加入解析队列？',
      confirmLabel: '加入',
    );
    if (!confirmed || !mounted) return;
    await ref.read(scraperQueueProvider.notifier).addTasks(candidates);
    if (!mounted) return;
    KikoenaiToast.success('已加入解析队列');
    ref.read(cloudFileEditProvider.notifier).exit();
  }

  Future<void> _playSelected(List<FileNode> selected) async {
    final progress = ValueNotifier(
      const CloudPlayableProgress(
        completedDirectories: 0,
        pendingDirectories: 0,
        collectedFiles: 0,
        failedDirectories: 0,
      ),
    );
    final dialog = CloudPlayableProgressDialog.show(context, progress);
    final source = ref.read(cloudDriveSourceProvider(widget.mode));
    final collection = await FileBrowserEditActions.collectCloudPlayable(
      source: source,
      selected: selected,
      onProgress: (value) => progress.value = value,
    );
    if (mounted) Navigator.of(context).pop();
    await dialog;
    progress.dispose();
    if (!mounted) return;

    if (collection.files.isEmpty) {
      KikoenaiToast.info(
        collection.failedDirectories > 0
            ? '没有收集到可播放文件，${collection.failedDirectories} 个文件夹读取失败'
            : '所选内容没有可播放的媒体',
      );
      return;
    }
    final failedText = collection.failedDirectories == 0
        ? ''
        : '\n${collection.failedDirectories} 个文件夹读取失败，已跳过。';
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '加入播放队列',
      content: '将 ${collection.files.length} 个文件加入播放队列？$failedText',
      confirmLabel: '加入',
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(playerControllerProvider.notifier)
        .addPlaybackItems(FileBrowserEditActions.playbackItems(collection.files));
    if (!mounted) return;
    ref.read(cloudFileEditProvider.notifier).exit();
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
