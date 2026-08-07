import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/global_exception.dart';
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
        onRefresh: () =>
            ref.invalidate(albumTrackFileNodeIndexProvider(work.id)),
      ),
    );
  }
}

/// 持有 [FileNodeLibraryIndex] 的区段主体。
///
/// 进入文件夹 / 返回 / 面包屑跳转均直接操作索引并 `setState` 触发重建。
/// 渲染 `PopScope > SliverMainAxisGroup[吸顶面包屑头, FileNodeBrowser]`。
class _AlbumFileSectionBody extends ConsumerStatefulWidget {
  const _AlbumFileSectionBody({
    required this.index,
    required this.work,
    this.onRefresh,
  });

  final FileNodeLibraryIndex index;
  final Work work;
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
    final path = node.path ?? node.mediaStreamUrl ?? '';
    if (path.isEmpty) return;
    _index.stepIn(NodeFolder(path));
    if (mounted) setState(() {});
  }

  void _goBack() {
    _index.stepOut();
    if (mounted) setState(() {});
  }

  void _jumpToBreadcrumb(int index) {
    _index.jumpToBreadcrumbIndex(index);
    if (mounted) setState(() {});
  }

  void _goHome() {
    _index.goHome();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sortOption = ref.watch(fileSortProvider);
    // 排序配置变更时重新应用排序
    _index.applySort(sortOption);

    final breadcrumb = _index.breadcrumbPath;
    final currentNodes = _index.currentChildren;
    final bool isRoot = _index.isHome;

    return PopScope(
      canPop: isRoot,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _goBack();
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
              onCrumbTap: _jumpToBreadcrumb,
              onRefresh: widget.onRefresh,
            ),
          ),
          FileNodeBrowser(
            currentNodes: currentNodes,
            work: widget.work,
            source: NodeSource.asmrServer,
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
