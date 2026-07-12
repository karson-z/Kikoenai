import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/global_exception.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';
import 'package:kikoenai/core/widgets/common/manage_playlist_dialog.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import 'package:kikoenai/features/album/presentation/widget/file_box.dart';

/// 本地作品文件区段：直接从 [FileScannerStorage] 读取已扫描的本地文件树，
/// 一次性构建 [FileNodeLibraryIndex] 并缓存。
class LocalAlbumFileSection extends ConsumerStatefulWidget {
  const LocalAlbumFileSection({super.key, required this.work});

  final Work work;

  @override
  ConsumerState<LocalAlbumFileSection> createState() =>
      _LocalAlbumFileSectionState();
}

class _LocalAlbumFileSectionState extends ConsumerState<LocalAlbumFileSection> {
  FileNodeLibraryIndex? _index;

  @override
  void initState() {
    super.initState();
    _index =
        FileScannerStorage().getWorkFileIndexLocally(widget.work.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_index == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('本地未找到该作品的文件', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return _AlbumFileSectionBody(
      index: _index!,
      work: widget.work,
      isLocal: true,
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
    final asyncData = ref.watch(trackFileNodeIndexProvider(work.id));

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
        isLocal: false,
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
    required this.isLocal,
  });

  final FileNodeLibraryIndex index;
  final Work work;
  final bool isLocal;

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
            ),
          ),
          FileNodeBrowser(
            currentNodes: currentNodes,
            work: widget.work,
            source:
                widget.isLocal ? NodeSource.localWork : NodeSource.asmrServer,
            config: FileBrowserConfig(
              showDownloadBadge: !widget.isLocal,
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
  final Work work;
  final double height;
  final void Function(int index) onCrumbTap;

  BreadcrumbHeaderDelegate({
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
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
  final Work work;
  final double height;
  final void Function(int index) onCrumbTap;

  const _BreadcrumbHeader({
    required this.work,
    required this.rootNodes,
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
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
