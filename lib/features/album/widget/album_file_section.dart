import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/common/global_exception.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';
import 'package:kikoenai/core/widgets/common/manage_playlist_dialog.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/provider/audio_file_provider.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai/features/file_sort/widget/file_sort_dialog.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_aggregation_controller.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_models.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

/// Displays media from the same source that owns the detail-page content.
class AlbumMediaSourceSection extends ConsumerWidget {
  const AlbumMediaSourceSection({super.key, required this.work});

  final Work work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(activeSiteIdProvider);
    final api = ref.watch(activeSiteApiProvider);
    if (api.supports(SiteFeature.tracks)) {
      return RemoteAlbumFileSection(
        key: ValueKey('tracks-$siteId-${work.id}'),
        work: work,
      );
    }

    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text('当前站点不支持作品媒体', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

/// 网络作品文件区段：直接监听 [trackFileNodeIndexProvider] 获取已构建好的
/// [FileNodeLibraryIndex]，无需再次 fromTree 转换。
class RemoteAlbumFileSection extends ConsumerWidget {
  const RemoteAlbumFileSection({super.key, required this.work});

  final Work work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(albumTrackFileNodeIndexProvider(work.id));

    return asyncData.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: LottieLoadingIndicator(message: 'loading...')),
      ),
      error: (err, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: err is GlobalException
              ? Text('GlobalException: ${err.message}\ncode=${err.code}')
              : Text('Error: $err'),
        ),
      ),
      data: (index) => _AlbumFileSectionBody(
        index: index,
        work: work,
        source: NodeSource.asmrServer,
        onRefresh: () =>
            ref.invalidate(albumTrackFileNodeIndexProvider(work.id)),
      ),
    );
  }
}

/// 持有 [FileNodeLibraryIndex] 的区段主体。
///
/// 导航（进入文件夹 / 返回 / 面包屑跳转 / 回根）直接保存在当前来源的
/// [FileNodeLibraryIndex] 中，因此不同媒体来源可以独立恢复浏览位置。渲染
/// `PopScope > SliverMainAxisGroup[吸顶面包屑头, FileNodeBrowser]`。
class _AlbumFileSectionBody extends ConsumerStatefulWidget {
  const _AlbumFileSectionBody({
    super.key,
    required this.index,
    required this.work,
    required this.source,
    this.onRefresh,
  });

  final FileNodeLibraryIndex index;
  final Work work;
  final NodeSource source;
  final VoidCallback? onRefresh;

  @override
  ConsumerState<_AlbumFileSectionBody> createState() =>
      _AlbumFileSectionBodyState();
}

class _AlbumFileSectionBodyState extends ConsumerState<_AlbumFileSectionBody> {
  late FileNodeLibraryIndex _index;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
  }

  @override
  void didUpdateWidget(covariant _AlbumFileSectionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.index, oldWidget.index)) {
      _index = widget.index;
    }
  }

  void _enterFolder(FileNode node) {
    final path = node.path ?? node.mediaStreamUrl;
    if (path == null || path.isEmpty) return;
    setState(() => _index.stepIn(NodeFolder(path)));
  }

  void _navigateBack() => setState(_index.stepOut);

  void _goHome() => setState(_index.goHome);

  void _jumpTo(int index) =>
      setState(() => _index.jumpToBreadcrumbIndex(index));

  @override
  Widget build(BuildContext context) {
    final sortOption = ref.watch(fileSortProvider);
    // 排序配置变更时重新应用排序
    _index.applySort(sortOption);

    final breadcrumb = _index.breadcrumbPath;
    final isRoot = _index.isHome;
    final currentNodes = _index.currentChildren;

    return PopScope(
      canPop: isRoot,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _navigateBack();
      },
      child: SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: BreadcrumbHeaderDelegate(
              work: widget.work,
              rootNodes: _index,
              breadcrumb: breadcrumb,
              onRootTap: _goHome,
              onCrumbTap: _jumpTo,
              onRefresh: widget.onRefresh,
            ),
          ),
          FileNodeBrowser(
            currentNodes: currentNodes,
            work: widget.work,
            source: widget.source,
            sourceResolver: (node) => node.source,
            config: const FileBrowserConfig(
              showDownloadBadge: true,
              enableImagePreview: true,
              enableTextPreview: true,
              enableAudioContextMenu: true,
            ),
            onEnterFolder: _enterFolder,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class DlAlbumMediaSourceSection extends ConsumerStatefulWidget {
  const DlAlbumMediaSourceSection({super.key, required this.work});

  final Work work;

  @override
  ConsumerState<DlAlbumMediaSourceSection> createState() =>
      _DlAlbumMediaSourceSectionState();
}

class _DlAlbumMediaSourceSectionState
    extends ConsumerState<DlAlbumMediaSourceSection> {
  final Map<String, double> _scrollOffsets = {};

  @override
  Widget build(BuildContext context) {
    final aggregation = ref.watch(dlMediaAggregationProvider(widget.work.id));
    final selected = aggregation.selectedSource;
    if (aggregation.visibleSources.isEmpty) {
      if (aggregation.hasLoading) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LottieLoadingIndicator(message: '正在查找媒体来源...'),
                TextButton.icon(
                  onPressed: () => _showSourceStatus(context),
                  icon: const Icon(Icons.dns_outlined),
                  label: const Text('查看来源状态'),
                ),
              ],
            ),
          ),
        );
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _DlMediaEmptyState(
          onRetry: () => ref
              .read(dlMediaAggregationProvider(widget.work.id).notifier)
              .refreshAll(),
          onShowStatus: () => _showSourceStatus(context),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _DlMediaSourceSelector(
            state: aggregation,
            onSelected: (key) => _selectSource(context, key),
            onShowStatus: () => _showSourceStatus(context),
            onRefreshAll: () => ref
                .read(dlMediaAggregationProvider(widget.work.id).notifier)
                .refreshAll(),
          ),
        ),
        if (selected != null)
          _AlbumFileSectionBody(
            key: ValueKey(selected.descriptor.key.storageKey),
            index: selected.index!,
            work: widget.work,
            source: selected.descriptor.nodeSource,
            onRefresh: () => ref
                .read(dlMediaAggregationProvider(widget.work.id).notifier)
                .refreshSource(selected.descriptor.key),
          ),
      ],
    );
  }

  void _selectSource(BuildContext context, DlMediaSourceKey nextKey) {
    final aggregation = ref.read(dlMediaAggregationProvider(widget.work.id));
    final currentKey = aggregation.selectedSource?.descriptor.key.storageKey;
    final scrollable = Scrollable.maybeOf(context);
    if (currentKey != null && scrollable != null) {
      _scrollOffsets[currentKey] = scrollable.position.pixels;
    }
    unawaited(
      ref
          .read(dlMediaAggregationProvider(widget.work.id).notifier)
          .selectSource(nextKey),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scrollable == null || !scrollable.position.hasPixels) {
        return;
      }
      final target =
          _scrollOffsets[nextKey.storageKey] ?? scrollable.position.pixels;
      scrollable.position.jumpTo(
        target.clamp(
          scrollable.position.minScrollExtent,
          scrollable.position.maxScrollExtent,
        ),
      );
    });
  }

  void _showSourceStatus(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _DlMediaSourceStatusSheet(workId: widget.work.id),
    );
  }
}

class _DlMediaSourceStatusSheet extends ConsumerWidget {
  const _DlMediaSourceStatusSheet({required this.workId});

  final int workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregation = ref.watch(dlMediaAggregationProvider(workId));
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('媒体来源', style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final source in aggregation.sources)
            ListTile(
              leading: _sourceStatusIcon(source.status),
              title: Text(source.descriptor.label),
              subtitle: Text(_sourceStatusText(source)),
              trailing: source.status == DlMediaResolveStatus.loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: '重新查找',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref
                          .read(dlMediaAggregationProvider(workId).notifier)
                          .refreshSource(source.descriptor.key),
                    ),
            ),
        ],
      ),
    );
  }

  static Widget _sourceStatusIcon(DlMediaResolveStatus status) {
    final icon = switch (status) {
      DlMediaResolveStatus.loading => Icons.hourglass_top,
      DlMediaResolveStatus.available => Icons.check_circle_outline,
      DlMediaResolveStatus.empty => Icons.search_off_outlined,
      DlMediaResolveStatus.error => Icons.error_outline,
      DlMediaResolveStatus.unavailable => Icons.link_off,
    };
    return Icon(icon);
  }

  static String _sourceStatusText(DlMediaSourceResult source) {
    return switch (source.status) {
      DlMediaResolveStatus.loading => '正在查找',
      DlMediaResolveStatus.available => '已找到资源',
      DlMediaResolveStatus.empty => '未找到该作品',
      DlMediaResolveStatus.error => source.message ?? '查找失败',
      DlMediaResolveStatus.unavailable => source.message ?? '尚未配置',
    };
  }
}

class _DlMediaSourceSelector extends StatelessWidget {
  const _DlMediaSourceSelector({
    required this.state,
    required this.onSelected,
    required this.onShowStatus,
    required this.onRefreshAll,
  });

  final DlMediaAggregationState state;
  final ValueChanged<DlMediaSourceKey> onSelected;
  final VoidCallback onShowStatus;
  final VoidCallback onRefreshAll;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedSource;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final source in state.visibleSources)
                    ButtonSegment<String>(
                      value: source.descriptor.key.storageKey,
                      label: Text(source.descriptor.label),
                    ),
                ],
                selected: {
                  if (selected != null) selected.descriptor.key.storageKey,
                },
                onSelectionChanged: (selection) {
                  final storageKey = selection.firstOrNull;
                  if (storageKey == null) return;
                  final source = state.visibleSources.firstWhere(
                    (item) => item.descriptor.key.storageKey == storageKey,
                  );
                  onSelected(source.descriptor.key);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: '来源状态',
            onPressed: onShowStatus,
            icon: Badge(
              isLabelVisible:
                  state.hasLoading ||
                  state.sources.any(
                    (source) => source.status == DlMediaResolveStatus.error,
                  ),
              child: const Icon(Icons.dns_outlined),
            ),
          ),
          IconButton(
            tooltip: '重新查找全部来源',
            onPressed: state.isRefreshingAll ? null : onRefreshAll,
            icon: state.isRefreshingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _DlMediaEmptyState extends StatelessWidget {
  const _DlMediaEmptyState({required this.onRetry, required this.onShowStatus});

  final VoidCallback onRetry;
  final VoidCallback onShowStatus;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text('没有找到可用的音视频资源'),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新查找'),
                ),
                OutlinedButton.icon(
                  onPressed: onShowStatus,
                  icon: const Icon(Icons.dns_outlined),
                  label: const Text('来源状态'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.localMedia),
                  icon: const Icon(Icons.folder_outlined),
                  label: const Text('本地媒体'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.cloudDrive),
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('云盘'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BreadcrumbHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<FileNode> breadcrumb;
  final FileNodeLibraryIndex rootNodes;
  final VoidCallback onRootTap;
  final VoidCallback? onRefresh;
  final Work work;
  final double height;
  final void Function(int index) onCrumbTap;

  BreadcrumbHeaderDelegate({
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
    this.onRefresh,
    this.height = 64,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _BreadcrumbHeader(
      work: work,
      breadcrumb: breadcrumb,
      rootNodes: rootNodes,
      onRootTap: onRootTap,
      onCrumbTap: onCrumbTap,
      onRefresh: onRefresh,
      height: height,
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant BreadcrumbHeaderDelegate oldDelegate) => true;
}

class _BreadcrumbHeader extends ConsumerWidget {
  final List<FileNode> breadcrumb;
  final FileNodeLibraryIndex rootNodes;
  final VoidCallback onRootTap;
  final VoidCallback? onRefresh;
  final Work work;
  final double height;
  final void Function(int index) onCrumbTap;

  const _BreadcrumbHeader({
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
    this.onRefresh,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);
    return Container(
      height: height,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: BreadcrumbBar(
              paths: breadcrumb.map((node) => node.title).toList(),
              onHomeTap: onRootTap,
              onPathTap: onCrumbTap,
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          ),
          IconButton(
            iconSize: 18,
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
            icon: Icon(
              Icons.sort,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            onPressed: () => FileSortDialog.show(context),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: '刷新当前来源',
              iconSize: 18,
              splashRadius: 20,
              padding: const EdgeInsets.all(8),
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
            ),
          IconButton(
            iconSize: 18,
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
            icon: Icon(
              Icons.library_music,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            onPressed: () {
              FileTreeWoltSheet.show(
                context: context,
                index: rootNodes,
                work: work,
              );
            },
          ),
        ],
      ),
    );
  }
}
