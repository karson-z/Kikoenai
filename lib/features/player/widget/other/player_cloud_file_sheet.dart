import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/back_button_interceptor.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/page/alist_server_management_page.dart';
import 'package:kikoenai/features/cloud_drive/page/webdav_settings_page.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai/features/file_browser/widget/cloud_playable_progress_dialog.dart';
import 'package:kikoenai/features/file_browser/widget/file_management_sheet.dart';
import 'package:kikoenai/features/player/provider/player_cloud_file_browser_controller.dart';
import 'package:kikoenai/features/player/provider/player_cloud_file_source_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

SliverWoltModalSheetPage buildPlayerCloudFilePage(PlaybackItem track) =>
    buildFileManagementPage(PlayerCloudFileSheet(track: track));

class PlayerCloudFileSheet extends ConsumerStatefulWidget {
  const PlayerCloudFileSheet({super.key, required this.track});
  final PlaybackItem track;

  @override
  ConsumerState<PlayerCloudFileSheet> createState() =>
      _PlayerCloudFileSheetState();
}

class _PlayerCloudFileSheetState extends ConsumerState<PlayerCloudFileSheet> {
  String? _legacyConnectionId;
  PlayerCloudFileSourceRequest get _request =>
      (track: widget.track, legacyConnectionId: _legacyConnectionId);

  void _back() => WoltModalSheet.of(context).popPage();

  Future<void> _manageSource() async {
    final webDav =
        widget.track.fileOrigin?.kind == FileOriginKind.webDav ||
        widget.track.siteId == webDavSiteId;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => webDav
            ? const WebDavSettingsPage()
            : const AlistServerManagementPage(),
      ),
    );
    if (mounted) ref.invalidate(playerCloudFileSourceProvider(_request));
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(playerCloudFileSourceProvider(_request));
    return resolved.when(
      loading: () => _shell(const Center(child: CircularProgressIndicator())),
      error: (error, _) => _shell(
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 36),
              const SizedBox(height: 16),
              Text(
                error is PlayerCloudSourceException
                    ? error.message
                    : '无法读取原始来源，请检查来源设置后重试',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (error is PlayerCloudSourceException && error.canBindLegacy)
                FilledButton(
                  onPressed: () => setState(
                    () => _legacyConnectionId = ref
                        .read(webDavConnectionControllerProvider)
                        .connectionId,
                  ),
                  child: const Text('确认使用当前连接'),
                )
              else
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(playerCloudFileSourceProvider(_request)),
                  child: const Text('重试'),
                ),
              TextButton(onPressed: _manageSource, child: const Text('来源设置')),
            ],
          ),
        ),
      ),
      data: (source) => PlayerCloudFileBrowser(
        key: ObjectKey(source),
        source: source,
        track: widget.track,
        onBack: _back,
        onManageSource: _manageSource,
      ),
    );
  }

  Widget _shell(Widget body) => BackButtonPriorityWrapper(
    zIndex: 110,
    onBack: () {
      _back();
      return true;
    },
    child: Column(
      children: [
        FileManagementHeader(onBack: _back, title: '文件管理'),
        Expanded(child: body),
      ],
    ),
  );
}

/// 独立浏览视图，亦可在测试中注入固定来源，不依赖播放器平台实例。
class PlayerCloudFileBrowser extends ConsumerStatefulWidget {
  const PlayerCloudFileBrowser({
    super.key,
    required this.source,
    required this.track,
    required this.onBack,
    required this.onManageSource,
  });
  final BoundPlayerCloudSource source;
  final PlaybackItem track;
  final VoidCallback onBack;
  final Future<void> Function() onManageSource;

  @override
  ConsumerState<PlayerCloudFileBrowser> createState() =>
      _PlayerCloudFileBrowserState();
}

class _PlayerCloudFileBrowserState
    extends ConsumerState<PlayerCloudFileBrowser> {
  late final PlayerCloudFileBrowserController _browser;
  final _scrollController = ScrollController();
  final Map<String, double> _offsets = {};
  bool _collecting = false;
  bool _cancelCollection = false;

  @override
  void initState() {
    super.initState();
    _browser = PlayerCloudFileBrowserController(widget.source);
    unawaited(_browser.refresh().then((_) => _revealCurrentFile()));
    if (widget.track.fileOrigin == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(playerControllerProvider.notifier)
            .rememberFileOrigin(widget.track, widget.source.origin);
      });
    }
  }

  @override
  void dispose() {
    _cancelCollection = true;
    _browser.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _back() {
    if (_collecting) {
      _cancelCollection = true;
      return;
    }
    if (_browser.isAtRoot) {
      widget.onBack();
    } else {
      unawaited(_navigate(NodeFolder.dirName(_browser.path)));
    }
  }

  Future<void> _navigate(String path) async {
    if (_scrollController.hasClients) {
      _offsets[_browser.path] = _scrollController.offset;
    }
    await _browser.navigate(path);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(
        (_offsets[_browser.path] ?? 0).clamp(
          0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  void _revealCurrentFile() {
    if (!mounted || !_browser.isCurrentDirectory) return;
    final index = _browser.state.visibleNodes.indexWhere(
      (node) => node.path == widget.source.origin.filePath,
    );
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(
        (index * 72.0).clamp(0, _scrollController.position.maxScrollExtent),
      );
    });
  }

  Future<void> _addSelection() async {
    if (_collecting || _browser.selected.isEmpty) return;
    setState(() {
      _collecting = true;
      _cancelCollection = false;
    });
    final progress = ValueNotifier(
      const CloudPlayableProgress(
        completedDirectories: 0,
        pendingDirectories: 0,
        collectedFiles: 0,
        failedDirectories: 0,
      ),
    );
    // 持有确切路由，立即完成的文件选择和异步收集都只关闭自己的进度页。
    final navigator = Navigator.of(context, rootNavigator: true);
    final progressRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: CloudPlayableProgressDialog(
          progress: progress,
          onCancel: () => _cancelCollection = true,
        ),
      ),
    );
    final dialog = navigator.push(progressRoute);
    void closeProgress() {
      if (progressRoute.isActive) navigator.removeRoute(progressRoute);
    }

    try {
      widget.source.validate();
      final collection = await FileBrowserEditActions.collectCloudPlayable(
        source: widget.source,
        selected: _browser.selected,
        isCancelled: () => _cancelCollection || !mounted,
        onProgress: (value) => progress.value = value,
      );
      closeProgress();
      await dialog;
      if (!mounted || collection.cancelled) return;
      widget.source.validate();
      if (collection.files.isEmpty) {
        KikoenaiToast.info(
          collection.failedDirectories > 0
              ? '没有收集到可播放文件，${collection.failedDirectories} 个文件夹读取失败'
              : '所选内容没有可播放的音频或视频',
        );
        return;
      }
      final partial = collection.failedDirectories > 0
          ? '\n${collection.failedDirectories} 个文件夹读取失败，将跳过。'
          : '';
      final confirmed = await KikoenaiAlertDialog.confirm(
        context,
        title: '加入播放队列',
        content: '将 ${collection.files.length} 个文件加入播放队列？$partial',
        confirmLabel: '加入',
      );
      if (!confirmed || !mounted) return;
      widget.source.validate();
      try {
        await ref
            .read(playerControllerProvider.notifier)
            .addAll(
              FileBrowserEditActions.playbackItems(
                collection.files,
              ).toMediaItems(),
            );
      } catch (_) {
        if (mounted) KikoenaiToast.error('加入播放队列失败，请重试');
        return;
      }
      if (mounted) {
        _browser.clearSelection();
        KikoenaiToast.success('已加入播放队列');
      }
    } catch (error) {
      closeProgress();
      await dialog;
      if (mounted) KikoenaiToast.error(widget.source.describeError(error));
    } finally {
      progress.dispose();
      if (mounted) setState(() => _collecting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _browser,
    builder: (context, _) {
      final state = _browser.state;
      final rootParts = FileOrigin.normalizePath(
        widget.source.origin.rootPath,
      ).split('/').where((part) => part.isNotEmpty).toList();
      final parts = _browser.path
          .split('/')
          .where((part) => part.isNotEmpty)
          .skip(rootParts.length)
          .toList();
      return FileManagementSheet(
        title: widget.source.label,
        onBack: _back,
        onClose: widget.onBack,
        segments: parts,
        onHome: () => unawaited(_navigate(_browser.rootPath)),
        onSegment: (index) => unawaited(
          _navigate('/${[...rootParts, ...parts.take(index + 1)].join('/')}'),
        ),
        nodes: state.visibleNodes,
        scrollController: _scrollController,
        selectedCount: _browser.selected.length,
        selectAllLabel: '全选已加载项（${state.nodes.length}）',
        selectionState: _browser.allLoadedSelected,
        onToggleAll: state.isLoading ? null : _browser.toggleAllLoaded,
        nodeSelection: _browser.isSelected,
        onToggleNode: _browser.toggle,
        onOpenFolder: (node) => unawaited(_navigate(node.path!)),
        currentFilePath: widget.source.origin.filePath,
        onLocate: state.isLoading || _browser.isLocating
            ? null
            : () async {
                await _browser.locateCurrentFile();
                _revealCurrentFile();
              },
        sortChoices: CloudDriveSort.values
            .map((sort) => (id: sort.name, label: sort.label))
            .toList(),
        selectedSort: state.sort.name,
        onSort: (id) => _browser.setSort(CloudDriveSort.values.byName(id)),
        onRefresh: state.isLoading ? null : () => unawaited(_browser.refresh()),
        onManageSource: widget.onManageSource,
        isAtRoot: _browser.isAtRoot,
        isLoading: state.isLoading,
        showProgress: _browser.isLocating || state.isLoadingMore,
        errorMessage: state.errorMessage,
        onRetry: state.hasLoadedDirectory && state.hasMore
            ? _browser.loadMore
            : _browser.refresh,
        loadMoreLabel: state.hasMore
            ? '加载更多（${state.nodes.length}/${state.totalCount}）'
            : null,
        onLoadMore: state.isLoadingMore || _browser.isLocating
            ? null
            : _browser.loadMore,
        currentFileMissing:
            _browser.isCurrentDirectory && !_browser.containsCurrentFile,
        onAddQueue: _collecting || _browser.selected.isEmpty
            ? null
            : _addSelection,
      );
    },
  );
}
