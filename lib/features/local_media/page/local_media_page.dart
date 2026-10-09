import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_breadcrumb_header.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/provider/file_bread_crumb_bar.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/file_browser/model/file_browser_edit_config.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_notifier.dart';
import 'package:kikoenai/features/file_browser/widget/file_browser_edit_bar.dart';
import 'package:kikoenai/features/file_sort/widget/file_sort_dialog.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../provider/file_path_notifier.dart';
import '../provider/file_scanner_notifier.dart';
import '../model/local_media_exclusion.dart';
import '../provider/local_media_exclusion_provider.dart';
import '../widget/excluded_media_sheet.dart';
import '../widget/local_media_header.dart';
import '../widget/local_media_toolbar.dart';
import '../widget/path_sheet.dart';

class LocalMediaPage extends ConsumerStatefulWidget {
  const LocalMediaPage({super.key});

  @override
  ConsumerState<LocalMediaPage> createState() => _LocalMediaPageState();
}

class _LocalMediaPageState extends ConsumerState<LocalMediaPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Object? _directoryKey;
  Object? _appliedExclusionKey;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 订阅最新的由对象驱动的单层切片文件树状态
    final scannerState = ref.watch(fileScannerProvider);

    final currentMode = scannerState.scanMode;
    // 面包屑链统一经由 FileNodeLibraryIndex 驱动的 BreadcrumbNotifier 提供。
    final breadcrumbNodes = ref.watch(
      breadcrumbProvider(BreadCrumbBarType.local),
    );
    final breadcrumbNotifier = ref.read(
      breadcrumbProvider(BreadCrumbBarType.local).notifier,
    );
    final List<String> breadcrumbPaths = breadcrumbNodes
        .map((node) => node.title)
        .toList();

    // 切换目录时清掉当前搜索，避免上一层的关键字继续过滤新目录。
    ref.listen<FileBrowserState>(fileScannerProvider, (previous, next) {
      if (previous != null &&
          previous.currentFolderPath != next.currentFolderPath &&
          _searchQuery.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _clearSearch();
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editing = ref.watch(localFileEditProvider).isEditing;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      bottomNavigationBar: editing ? _buildEditBar() : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LocalMediaHeader(value: currentMode, onChanged: _changeMode),
            Expanded(
              child: scannerState.rootPath.isEmpty
                  ? _buildEmptyStateView(context, currentMode)
                  : _buildBrowser(
                      scannerState,
                      breadcrumbPaths,
                      breadcrumbNotifier,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowser(
    FileBrowserState scannerState,
    List<String> breadcrumbPaths,
    BreadcrumbNotifier breadcrumbNotifier,
  ) {
    final scannerNotifier = ref.read(fileScannerProvider.notifier);
    final exclusions = ref.watch(
      localMediaExclusionsProvider(scannerState.rootPath),
    );
    _scheduleExclusionUpdate(scannerState.rootPath, exclusions);
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleNodes = normalizedQuery.isEmpty
        ? scannerState.children
        : scannerState.children
              .where(
                (node) => node.title.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);
    final directoryKey = Object.hash(
      scannerState.rootPath,
      scannerState.currentFolderPath,
      normalizedQuery,
    );
    if (_directoryKey != directoryKey) {
      _directoryKey = directoryKey;
      final visibleKeys = visibleNodes.map((node) => node.keyId).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _directoryKey != directoryKey) return;
        ref.read(localFileEditProvider.notifier).retainVisible(visibleKeys);
      });
    }
    final edit = ref.watch(localFileEditProvider);

    return PopScope(
      canPop: scannerState.isHome,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _clearSearch();
        scannerNotifier.stepOut();
      },
      child: ScrollAwareToolbarLayout(
        toolbar: LocalMediaToolbar(
          isRoot: scannerState.isHome,
          isScanning: scannerState.isScanning,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          onBack: () {
            _clearSearch();
            scannerNotifier.stepOut();
          },
          onManagePaths: () => _showPathManager(scannerState.scanMode),
          onRefresh: scannerNotifier.refreshCurrentTarget,
          onSearchChanged: (query) => setState(() => _searchQuery = query),
          onClearSearch: _clearSearch,
          onSort: () => FileSortDialog.show(context),
          onShowExcluded: () =>
              ExcludedMediaSheet.show(context, scannerState.rootPath),
        ),
        child: RefreshIndicator(
          onRefresh: scannerState.isScanning
              ? () async {}
              : scannerNotifier.refreshCurrentTarget,
          child: CustomScrollView(
            key: ValueKey(
              'local_media_${scannerState.rootPath}_${scannerState.currentFolderPath}',
            ),
            physics: nonBouncingRefreshScrollPhysics,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: FileBreadcrumbHeaderDelegate(
                  segments: breadcrumbPaths,
                  onHomeTap: () {
                    _clearSearch();
                    breadcrumbNotifier.goHome();
                  },
                  onSegmentTap: (index) {
                    _clearSearch();
                    breadcrumbNotifier.jumpTo(index);
                  },
                ),
              ),
              if (scannerState.isScanning && scannerState.children.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleNodes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildDirectoryEmptyState(normalizedQuery.isNotEmpty),
                )
              else ...[
                FileNodeBrowser(
                  currentNodes: visibleNodes,
                  work: null,
                  source: NodeSource.localSingle,
                  config: FileBrowserConfig(
                    showFolderStatus: true,
                    subtitlesCopyMode:
                        scannerState.scanMode == ScanMode.subtitles,
                  ),
                  onEnterFolder: (node) {
                    if (node.path == null) return;
                    _clearSearch();
                    scannerNotifier.stepIn(NodeFolder(node.path!));
                  },
                  workResolver: (node) => node.workId == null
                      ? null
                      : ScraperStorage().getWork(node.workId!),
                  sourceResolver: (node) => node.workId == null
                      ? NodeSource.localSingle
                      : NodeSource.localWork,
                  editConfig: FileBrowserEditConfig(
                    isEditing: edit.isEditing,
                    selectedKeys: edit.selectedKeys,
                    onToggle: (keyId) => ref
                        .read(localFileEditProvider.notifier)
                        .toggle(keyId),
                    onRequestEdit: (keyId) =>
                        ref.read(localFileEditProvider.notifier).enter(keyId),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    child: Text(
                      '已显示 ${visibleNodes.length} / ${scannerState.children.length} 项',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryEmptyState(bool isSearch) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.folder_open,
            size: 60,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            isSearch ? '没有匹配的文件' : '该目录为空',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(BuildContext context, ScanMode mode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.surfaceTint,
          ),
          const SizedBox(height: 16),
          Text("这里空空如也", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            "点击下方按钮管理并添加文件夹",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showPathManager(mode),
            icon: const Icon(Icons.add),
            label: const Text("添加文件夹"),
          ),
        ],
      ),
    );
  }

  Future<void> _changeMode(ScanMode mode) async {
    final scannerState = ref.read(fileScannerProvider);
    if (mode == scannerState.scanMode) return;

    final targetNotifier = ref.read(scanTargetsProvider.notifier);
    final targets = targetNotifier.getTargetsByMode(mode);
    if (targets.isEmpty) {
      await _showPathManager(mode);
      return;
    }

    final target = targets.first;
    await targetNotifier.selectTarget(path: target.path, mode: target.scanMode);
    if (!mounted) return;
    _clearSearch();
    await ref.read(fileScannerProvider.notifier).changeActiveTarget(target);
  }

  Future<void> _showPathManager(ScanMode mode) async {
    await PathManagerSheet.show(context, initialMode: mode);
    if (mounted) _clearSearch();
  }

  void _scheduleExclusionUpdate(
    String rootPath,
    List<LocalMediaExclusion> exclusions,
  ) {
    final key = Object.hash(
      rootPath,
      Object.hashAll(
        exclusions.map((entry) => '${entry.relativePath}:${entry.isFolder}'),
      ),
    );
    if (_appliedExclusionKey == key) return;
    _appliedExclusionKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _appliedExclusionKey != key) return;
      ref.read(fileScannerProvider.notifier).applyExclusions(exclusions);
    });
  }

  Widget _buildEditBar() {
    final edit = ref.watch(localFileEditProvider);
    final scanner = ref.watch(fileScannerProvider);
    final visible = _visibleNodes(scanner);
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
    final canPlay = scanner.scanMode != ScanMode.subtitles && selected.isNotEmpty;
    return FileBrowserEditBar(
      selectedCount: selected.length,
      allSelected: edit.allVisibleSelected(visible.map((node) => node.keyId)),
      canParse: canParse,
      canPlay: canPlay,
      canExclude: true,
      onToggleAll: () => ref
          .read(localFileEditProvider.notifier)
          .toggleVisibleSelection(visible.map((node) => node.keyId)),
      onParse: () => _parseSelected(selected, parsed, queue),
      onPlay: () => _playSelected(selected),
      onExclude: () => _excludeSelected(scanner.rootPath, selected),
      onDone: () => ref.read(localFileEditProvider.notifier).exit(),
    );
  }

  List<FileNode> _visibleNodes(FileBrowserState scanner) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return scanner.children;
    return scanner.children
        .where((node) => node.title.toLowerCase().contains(query))
        .toList(growable: false);
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
    ref.read(localFileEditProvider.notifier).exit();
  }

  Future<void> _playSelected(List<FileNode> selected) async {
    final index = ref.read(fileScannerProvider.notifier).libraryIndex;
    if (index == null) return;
    final files = FileBrowserEditActions.collectLocalPlayable(
      index: index,
      selected: selected,
    );
    if (files.isEmpty) {
      KikoenaiToast.info('所选内容没有可播放的媒体');
      return;
    }
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '加入播放队列',
      content: '将 ${files.length} 个文件加入播放队列？',
      confirmLabel: '加入',
    );
    if (!confirmed || !mounted) return;
    final items = FileBrowserEditActions.playbackItems(
      files,
      workOf: (node) => node.workId == null
          ? null
          : ScraperStorage().getWork(node.workId!),
    );
    await ref.read(playerControllerProvider.notifier).addPlaybackItems(items);
    if (!mounted) return;
    ref.read(localFileEditProvider.notifier).exit();
  }

  Future<void> _excludeSelected(String rootPath, List<FileNode> selected) async {
    final entries = FileBrowserEditActions.exclusionsFor(
      rootPath: rootPath,
      selected: selected,
    );
    if (entries.isEmpty) return;
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '排除所选内容',
      content: '从当前媒体库隐藏 ${entries.length} 项？可以稍后在已排除列表中恢复。',
      confirmLabel: '排除',
    );
    if (!confirmed || !mounted) return;
    await ref.read(localMediaExclusionRepositoryProvider).addAll(entries);
    if (!mounted) return;
    ref.read(localFileEditProvider.notifier).exit();
    KikoenaiToast.success('已排除');
  }

  void _clearSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    if (_searchQuery.isNotEmpty && mounted) {
      setState(() => _searchQuery = '');
    }
  }
}
