import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_breadcrumb_header.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_selection.dart';
import 'package:kikoenai/core/service/file/local_scan_exclusions.dart';
import 'package:kikoenai/features/album/widget/file_browser_edit_bar.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/provider/file_bread_crumb_bar.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/file_sort/widget/file_sort_dialog.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../provider/file_path_notifier.dart';
import '../provider/file_scanner_notifier.dart';
import '../widget/local_media_header.dart';
import '../widget/local_media_toolbar.dart';
import '../widget/path_sheet.dart';
import '../widget/batch_rename_dialog.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isEditing = false;
  final Set<String> _selectedKeys = {};

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
    final List<String> breadcrumbPaths =
        breadcrumbNodes.map((node) => node.title).toList();

    // 3. 监听扫描流异步完成的副作用（仅在扫描状态由 true 变为 false 且存在有效节点时触发弹窗）
    ref.listen<FileBrowserState>(fileScannerProvider, (previous, next) {
      if (previous != null &&
          previous.currentFolderPath != next.currentFolderPath &&
          _searchQuery.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _clearSearch();
        });
      }
      if (previous != null &&
          (previous.currentFolderPath != next.currentFolderPath ||
              previous.rootPath != next.rootPath ||
              previous.scanMode != next.scanMode)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_selectedKeys.clear);
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LocalMediaHeader(value: currentMode, onChanged: _changeMode),
            if (_isEditing && scannerState.rootPath.isNotEmpty)
              FileBrowserEditBar(
                selectedCount: _selectedKeys.length,
                onSelectAll: () => _selectNodes(scannerState.children),
                onSelectEligible: () => _selectNodes(eligibleScraperNodes(
                  scannerState.children,
                  ref.read(scraperQueueProvider),
                )),
                onEnqueue: () => _enqueueSelected(scannerState.children),
                onExclude: () => _excludeSelected(scannerState),
                onManageExclusions: () => _manageExclusions(scannerState),
                onRename: () => _renameSelected(scannerState),
              ),
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
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleNodes = _isEditing || normalizedQuery.isEmpty
        ? scannerState.children
        : scannerState.children
            .where(
              (node) => node.title.toLowerCase().contains(normalizedQuery),
            )
            .toList(growable: false);

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
          isEditing: _isEditing,
          onToggleEdit: () {
            if (!_isEditing) _clearSearch();
            setState(() {
              _isEditing = !_isEditing;
              _selectedKeys.clear();
            });
          },
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
                  selectedKeys: _isEditing ? _selectedKeys : null,
                  onSelectionChanged: _toggleSelection,
                  work: null,
                  source: NodeSource.localSingle,
                  config: FileBrowserConfig(
                    showFolderStatus: true,
                    subtitlesCopyMode:
                        scannerState.scanMode == ScanMode.subtitles,
                    enableFolderLongPress: true,
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
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    child: Text(
                      '已显示 ${visibleNodes.length} / ${scannerState.children.length} 项',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

  void _clearSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    if (_searchQuery.isNotEmpty && mounted) {
      setState(() => _searchQuery = '');
    }
  }

  void _toggleSelection(FileNode node) => setState(() {
        final key = browserSelectionKey(node);
        if (!_selectedKeys.add(key)) _selectedKeys.remove(key);
      });

  void _selectNodes(Iterable<FileNode> nodes) => setState(() {
        _selectedKeys
          ..clear()
          ..addAll(nodes.map(browserSelectionKey));
      });

  List<FileNode> _selectedFrom(Iterable<FileNode> nodes) => nodes
      .where((node) => _selectedKeys.contains(browserSelectionKey(node)))
      .toList();

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _enqueueSelected(List<FileNode> nodes) {
    final tasks = eligibleScraperNodes(
      _selectedFrom(nodes),
      ref.read(scraperQueueProvider),
    );
    if (tasks.isNotEmpty) {
      final notifier = ref.read(scraperQueueProvider.notifier);
      notifier.addTasks(tasks);
      notifier.start();
    }
    _message('已加入 ${tasks.length} 个待解析作品');
  }

  Future<void> _excludeSelected(FileBrowserState scannerState) async {
    final paths = _selectedFrom(scannerState.children)
        .map((node) => node.path ?? node.mediaStreamUrl)
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    await const LocalScanExclusions().add(
      scannerState.scanMode,
      scannerState.rootPath,
      paths,
    );
    if (!mounted) return;
    setState(_selectedKeys.clear);
    await ref.read(fileScannerProvider.notifier).refreshCurrentTarget();
    if (mounted) _message('已排除 ${paths.length} 项');
  }

  Future<void> _manageExclusions(FileBrowserState scannerState) async {
    final rules = const LocalScanExclusions().getRules(
      scannerState.scanMode,
      scannerState.rootPath,
    );
    final selected = <String>{};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: const Text('排除项管理'),
          content: SizedBox(
            width: 420,
            height: 320,
            child: rules.isEmpty
                ? const Center(child: Text('暂无排除项'))
                : ListView(
                    children: [
                      for (final path in rules)
                        CheckboxListTile(
                          value: selected.contains(path),
                          title: Text(path,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          onChanged: (_) => update(() {
                            if (!selected.add(path)) selected.remove(path);
                          }),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('关闭')),
            TextButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      await const LocalScanExclusions().remove(
                        scannerState.scanMode,
                        scannerState.rootPath,
                        selected,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await ref
                          .read(fileScannerProvider.notifier)
                          .refreshCurrentTarget();
                    },
              child: const Text('恢复所选'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameSelected(FileBrowserState scannerState) async {
    final changed = await BatchRenameDialog.show(
      context,
      _selectedFrom(scannerState.children),
    );
    if (!mounted || !changed) return;
    setState(_selectedKeys.clear);
    await ref.read(fileScannerProvider.notifier).refreshCurrentTarget();
  }
}
