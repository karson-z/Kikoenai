import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/provider/file_manage_provider.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai/features/file_browser/widget/file_management_sheet.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_option.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../service/file/file_node_library_index.dart';
import '../layout/app_toast.dart';

/// 兼容现有作品页、播放页入口；索引来源也使用统一文件管理弹窗。
class FileTreeWoltSheet {
  static Future<void> show({
    required BuildContext context,
    required FileNodeLibraryIndex index,
    Work? work,
    bool isFirstPage = true,
  }) async {
    await WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: fileManagementModalType,
      pageListBuilder: (modalContext) => [
        buildPage(
          modalContext,
          index: index,
          work: work,
          isFirstPage: isFirstPage,
        ),
      ],
    );
  }

  static SliverWoltModalSheetPage buildPage(
    BuildContext context, {
    required FileNodeLibraryIndex index,
    required Work? work,
    required bool isFirstPage,
    PlaybackItem? track,
  }) => buildFileManagementPage(
    ProviderScope(
      // 每次打开拥有独立勾选状态，保留原有递归选择和半选规则。
      overrides: [
        fileSelectionProvider.overrideWith(FileSelectionNotifier.new),
      ],
      child: IndexedFileManagementSheet(
        index: index,
        work: work,
        track: track,
        isFirstPage: isFirstPage,
      ),
    ),
  );
}

/// 索引适配层：仅负责索引导航、递归选择、排序偏好和下载操作。
class IndexedFileManagementSheet extends ConsumerStatefulWidget {
  const IndexedFileManagementSheet({
    super.key,
    required this.index,
    required this.isFirstPage,
    this.work,
    this.track,
  });
  final FileNodeLibraryIndex index;
  final bool isFirstPage;
  final Work? work;
  final PlaybackItem? track;

  @override
  ConsumerState<IndexedFileManagementSheet> createState() =>
      _IndexedFileManagementSheetState();
}

class _IndexedFileManagementSheetState
    extends ConsumerState<IndexedFileManagementSheet> {
  final _scrollController = ScrollController();
  final Map<String, double> _offsets = {};
  bool _adding = false;
  bool _downloading = false;

  FileNodeLibraryIndex get _index => widget.index;
  String get _path => _index.currentFolder?.normalized ?? _index.rootPath;
  String? get _currentFilePath {
    final track = widget.track;
    if (track == null) return null;
    return _index.nodeByKey[track.id]?.path ??
        (track.isLocal ? track.url : null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrentFile());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.isFirstPage) {
      Navigator.of(context).pop();
    } else {
      WoltModalSheet.of(context).popPage();
    }
  }

  void _back() {
    if (_index.isHome) {
      _close();
    } else {
      _navigate(_index.stepOut);
    }
  }

  void _navigate(VoidCallback action) {
    if (_scrollController.hasClients) {
      _offsets[_path] = _scrollController.offset;
    }
    setState(action);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(
        (_offsets[_path] ?? 0).clamp(
          0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  void _revealCurrentFile() {
    if (!mounted || !_scrollController.hasClients) return;
    final index = _index.currentChildren.indexWhere(
      (node) => node.path == _currentFilePath,
    );
    if (index >= 0) {
      _scrollController.jumpTo(
        (index * 72.0).clamp(0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  Future<void> _addSelection(List<FileNode> files) async {
    if (_adding || files.isEmpty) return;
    setState(() => _adding = true);
    try {
      final work = widget.work;
      final items = FileBrowserEditActions.playbackItems(
        files,
        workOf: work == null ? null : (_) => work,
      );
      await ref
          .read(playerControllerProvider.notifier)
          .addAll(items.toMediaItems());
      if (!mounted) return;
      KikoenaiToast.success('已加入播放队列');
      _close();
    } catch (_) {
      if (mounted) KikoenaiToast.error('加入播放队列失败，请重试');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _download(List<FileNode> files) async {
    if (_downloading || files.isEmpty || widget.work == null) return;
    setState(() => _downloading = true);
    final work = widget.work!;
    try {
      await ref
          .read(downloadServiceProvider)
          .enqueueBatch(
            selectedFiles: files,
            index: _index,
            title: work.title ?? work.name ?? '未知作品',
            metaData: work.toJson(),
          );
      if (!mounted) return;
      KikoenaiToast.success('已加入下载队列');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) KikoenaiToast.error('加入下载队列失败');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(fileSelectionProvider);
    final selection = ref.read(fileSelectionProvider.notifier);
    final sort = ref.watch(fileSortProvider);
    _index.applySort(sort);
    final downloadedIds = ref
        .watch(completedTasksProvider)
        .map((task) => task.task.taskId)
        .toSet();
    final playable = selected.where((node) => node.isPlayable).toList();
    final downloads = selected
        .where(
          (node) =>
              !node.isFolder &&
              node.isRemote &&
              !downloadedIds.contains(node.hash),
        )
        .toList();
    final paths = _index.breadcrumbPath;
    final title =
        widget.work?.title ??
        widget.work?.name ??
        (_index.isLocalContent ? '本地文件' : '作品文件');
    return FileManagementSheet(
      title: title,
      onBack: _back,
      onClose: _close,
      segments: paths.map((node) => node.title).toList(),
      onHome: () => _navigate(_index.goHome),
      onSegment: (index) =>
          _navigate(() => _index.jumpToBreadcrumbIndex(index)),
      nodes: _index.currentChildren,
      scrollController: _scrollController,
      selectedCount: selected.length,
      selectionSize: selectedFilesTotalSize(selected),
      selectAllLabel: '全选全部文件（${_index.nodeByKey.length}）',
      selectionState: selection.getRootStateForIndex(_index),
      onToggleAll: () => selection.toggleSelectAllForIndex(_index),
      nodeSelection: (node) => selection.getNodeStateForIndex(node, _index),
      onToggleNode: (node) => selection.toggleNodeForIndex(node, _index),
      onOpenFolder: (node) =>
          _navigate(() => _index.stepIn(NodeFolder(node.path!))),
      folderDescription: (node) =>
          '${_index.directItemCount(NodeFolder(node.path!)).total} 项',
      isDownloaded: (node) =>
          !node.isFolder && downloadedIds.contains(node.hash),
      showDownload: _index.hasRemoteContent,
      onDownload: widget.work == null || downloads.isEmpty || _downloading
          ? null
          : () => _download(downloads),
      currentFilePath: _currentFilePath,
      onLocate: () {
        final path = _currentFilePath;
        if (path == null) return;
        _navigate(() => _index.jumpToFilePath(path));
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _revealCurrentFile(),
        );
      },
      isAtRoot: _index.isHome,
      sortChoices: [
        for (final field in FileSortField.values)
          for (final descending
              in field == FileSortField.defaultSort ? [false] : [false, true])
            (
              id: '${field.name}:$descending',
              label: _sortLabel(field, descending),
            ),
      ],
      selectedSort:
          '${sort.field.name}:${sort.field == FileSortField.defaultSort ? false : sort.descending}',
      onSort: (id) {
        final parts = id.split(':');
        ref
            .read(fileSortProvider.notifier)
            .update(
              FileSortOption(
                field: FileSortField.values.byName(parts[0]),
                descending: parts[1] == 'true',
              ),
            );
      },
      onAddQueue: _adding || playable.isEmpty
          ? null
          : () => _addSelection(playable),
    );
  }
}

String _sortLabel(FileSortField field, bool descending) {
  final label = switch (field) {
    FileSortField.defaultSort => '默认',
    FileSortField.title => '标题',
    FileSortField.titleNumber => '标题序号',
    FileSortField.duration => '时长',
    FileSortField.size => '文件大小',
  };
  return field == FileSortField.defaultSort
      ? label
      : '$label · ${descending ? '降序' : '升序'}';
}
