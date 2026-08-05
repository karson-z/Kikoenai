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

const String albumLocalMediaSourceId = 'local';

/// Displays every registered media source that can resolve the current work.
///
/// Metadata remains owned by the detail-page entry source. Switching this
/// control only replaces the file area below it.
class AlbumMediaSourcesSection extends ConsumerStatefulWidget {
  const AlbumMediaSourcesSection({
    super.key,
    required this.work,
    required this.preferredSourceId,
  });

  final Work work;
  final String preferredSourceId;

  @override
  ConsumerState<AlbumMediaSourcesSection> createState() =>
      _AlbumMediaSourcesSectionState();
}

class _AlbumMediaSourcesSectionState
    extends ConsumerState<AlbumMediaSourcesSection> {
  String? _selectedSourceId;

  @override
  void didUpdateWidget(covariant AlbumMediaSourcesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work.id != widget.work.id ||
        oldWidget.preferredSourceId != widget.preferredSourceId) {
      _selectedSourceId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceIds = <String>[
      if (ref.watch(localWorkFileIndexProvider(widget.work.id)) != null)
        albumLocalMediaSourceId,
      ...ref
          .watch(albumMediaSiteRuntimesProvider)
          .map((runtime) => runtime.siteId),
    ];
    if (sourceIds.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('未找到可用的媒体来源', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final selectedId = _resolveSelectedSourceId(sourceIds);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text('媒体来源', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: sourceIds
                          .map(
                            (sourceId) => ButtonSegment<String>(
                              value: sourceId,
                              label: Text(_sourceLabel(sourceId)),
                              icon: Icon(_sourceIcon(sourceId), size: 18),
                            ),
                          )
                          .toList(growable: false),
                      selected: {selectedId},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        setState(() => _selectedSourceId = selection.first);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildSelectedSection(selectedId),
      ],
    );
  }

  String _resolveSelectedSourceId(List<String> sourceIds) {
    final selectedId = _selectedSourceId;
    if (selectedId != null && sourceIds.contains(selectedId)) {
      return selectedId;
    }
    if (sourceIds.contains(widget.preferredSourceId)) {
      return widget.preferredSourceId;
    }
    return sourceIds.first;
  }

  String _sourceLabel(String sourceId) {
    if (sourceId == albumLocalMediaSourceId) return '本地';
    return ref.watch(siteInfoByIdProvider(sourceId)).name;
  }

  IconData _sourceIcon(String sourceId) {
    if (sourceId == albumLocalMediaSourceId) return Icons.folder_outlined;
    final api = ref.watch(siteApiByIdProvider(sourceId));
    return api.supports(SiteFeature.tracks)
        ? Icons.cloud_outlined
        : Icons.storage_outlined;
  }

  Widget _buildSelectedSection(String sourceId) {
    if (sourceId == albumLocalMediaSourceId) {
      return LocalAlbumFileSection(work: widget.work);
    }

    final api = ref.watch(siteApiByIdProvider(sourceId));
    if (api.supports(SiteFeature.tracks)) {
      return RemoteAlbumFileSection(
        key: ValueKey('tracks-$sourceId-${widget.work.id}'),
        work: widget.work,
        contentId: SiteContentId(
          siteId: sourceId,
          remoteId: sourceId == widget.work.siteId
              ? widget.work.remoteId ?? widget.work.id.toString()
              : _rjNumberFor(widget.work).toString(),
        ),
      );
    }

    return FileSystemAlbumFileSection(
      key: ValueKey('filesystem-$sourceId-${widget.work.id}'),
      siteId: sourceId,
      rjCode: _rjCodeFor(widget.work),
      work: widget.work,
    );
  }
}

/// 本地作品文件区段：直接从 [FileScannerStorage] 读取已扫描的本地文件树，
/// 一次性构建 [FileNodeLibraryIndex] 并缓存。
class LocalAlbumFileSection extends ConsumerWidget {
  const LocalAlbumFileSection({super.key, required this.work});

  final Work work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(localWorkFileIndexProvider(work.id));
    if (index == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('本地未找到该作品的文件', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return _AlbumFileSectionBody(index: index, work: work, isLocal: true);
  }
}

/// 网络作品文件区段：直接监听 [trackFileNodeIndexProvider] 获取已构建好的
/// [FileNodeLibraryIndex]，无需再次 fromTree 转换。
class RemoteAlbumFileSection extends ConsumerWidget {
  const RemoteAlbumFileSection({
    super.key,
    required this.work,
    required this.contentId,
  });

  final Work work;
  final SiteContentId contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(trackFileNodeIndexProvider(contentId));

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
        onRefresh: () => ref.invalidate(trackFileNodeIndexProvider(contentId)),
      ),
    );
  }
}

/// File-system media source used by runtimes such as asmr.gay.
///
/// The first request searches the RJ code. Entering a matched directory then
/// switches to the site's existing paged file-system browse API.
class FileSystemAlbumFileSection extends ConsumerStatefulWidget {
  const FileSystemAlbumFileSection({
    super.key,
    required this.siteId,
    required this.rjCode,
    required this.work,
  });

  final String siteId;
  final String rjCode;
  final Work work;

  @override
  ConsumerState<FileSystemAlbumFileSection> createState() =>
      _FileSystemAlbumFileSectionState();
}

class _FileSystemAlbumFileSectionState
    extends ConsumerState<FileSystemAlbumFileSection> {
  static const int _pageSize = 100;

  List<FileNode> _nodes = const [];
  final List<String> _pathHistory = [];
  int _currentPage = 0;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Object? _error;
  int _requestSerial = 0;

  String? get _currentPath => _pathHistory.isEmpty ? null : _pathHistory.last;

  bool get _hasMore => _currentPage * _pageSize < _totalCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCurrent(reset: true);
    });
  }

  @override
  void didUpdateWidget(covariant FileSystemAlbumFileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteId == widget.siteId &&
        oldWidget.rjCode == widget.rjCode) {
      return;
    }
    _pathHistory.clear();
    _loadCurrent(reset: true);
  }

  Future<void> _loadCurrent({required bool reset}) async {
    if (!reset && (_isLoading || _isLoadingMore || !_hasMore)) return;

    final api = ref.read(siteApiByIdProvider(widget.siteId));
    final path = _currentPath;
    final nextPage = reset ? 1 : _currentPage + 1;
    final requestSerial = ++_requestSerial;

    setState(() {
      if (reset) {
        _isLoading = true;
        _nodes = const [];
        _currentPage = 0;
        _totalCount = 0;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      final List<FileNode> loadedNodes;
      final int totalCount;
      if (api is AsmrGaySiteApi) {
        final PagedResult<FileNode> result;
        if (path == null) {
          result = await api.searchAsFileNodes(
            FsSearchRequest(
              parent: '/',
              keywords: widget.rjCode,
              scope: 1,
              page: nextPage,
              perPage: _pageSize,
            ),
          );
        } else {
          result = await api.browseAsFileNodes(
            FsListRequest(path: path, page: nextPage, perPage: _pageSize),
          );
        }
        loadedNodes = result.items
            .map((node) => node.copyWith(workId: widget.work.id))
            .toList(growable: false);
        totalCount = result.pagination.totalCount;
      } else {
        final FsBrowseResult result;
        if (path == null) {
          result = await api.searchFileSystem(
            FsSearchRequest(
              parent: '/',
              keywords: widget.rjCode,
              scope: 1,
              page: nextPage,
              perPage: _pageSize,
            ),
          );
        } else {
          result = await api.browseFileSystem(
            FsListRequest(path: path, page: nextPage, perPage: _pageSize),
          );
        }
        loadedNodes = result.content
            .map(
              (entry) =>
                  _toFileNode(api, entry, parentPath: path ?? entry.parent),
            )
            .toList(growable: false);
        totalCount = result.total;
      }
      if (!mounted || requestSerial != _requestSerial) return;

      var incoming = loadedNodes;

      if (path == null) {
        final exactMatches = incoming
            .where((node) => _containsRj(node.effectivePath, widget.rjCode))
            .toList(growable: false);
        if (exactMatches.isNotEmpty) incoming = exactMatches;

        if (reset && totalCount == 1 && incoming.length == 1) {
          final onlyMatch = incoming.single;
          if (onlyMatch.isFolder && onlyMatch.path != null) {
            _pathHistory.add(onlyMatch.path!);
            await _loadCurrent(reset: true);
            return;
          }
        }
      }

      setState(() {
        _nodes = reset ? incoming : _appendUnique(_nodes, incoming);
        _currentPage = nextPage;
        _totalCount = totalCount;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[AlbumMedia] ${widget.siteId} 加载 ${path ?? widget.rjCode} 失败: '
        '$error\n$stackTrace',
      );
      if (!mounted || requestSerial != _requestSerial) return;
      setState(() {
        _error = error;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _enterFolder(FileNode node) async {
    final path = node.path;
    if (path == null || path.isEmpty) return;
    _pathHistory.add(path);
    await _loadCurrent(reset: true);
  }

  Future<void> _goHome() async {
    if (_pathHistory.isEmpty) return;
    _pathHistory.clear();
    await _loadCurrent(reset: true);
  }

  Future<void> _goBack() async {
    if (_pathHistory.isEmpty) return;
    _pathHistory.removeLast();
    await _loadCurrent(reset: true);
  }

  Future<void> _jumpToBreadcrumb(int index) async {
    if (index < 0 || index >= _pathHistory.length) return;
    _pathHistory.removeRange(index + 1, _pathHistory.length);
    await _loadCurrent(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _nodes.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null && _nodes.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: Center(
            child: FilledButton.icon(
              onPressed: () => _loadCurrent(reset: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ),
        ),
      );
    }

    if (_nodes.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              '${widget.siteId} 未找到 ${widget.rjCode}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: _pathHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _FileSystemBreadcrumbHeaderDelegate(
              paths: _pathHistory
                  .map((path) => NodeFolder(path).name)
                  .toList(growable: false),
              onHomeTap: _goHome,
              onPathTap: _jumpToBreadcrumb,
              onRefresh: () => _loadCurrent(reset: true),
            ),
          ),
          FileNodeBrowser(
            currentNodes: _nodes,
            work: widget.work,
            source: _sourceForSite(widget.siteId),
            config: const FileBrowserConfig(
              enableImagePreview: true,
              enableTextPreview: true,
              enableAudioContextMenu: true,
              showFileMetaInfo: true,
            ),
            onEnterFolder: _enterFolder,
          ),
          if (_hasMore || _isLoadingMore)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: () => _loadCurrent(reset: false),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('加载更多'),
                        ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  FileNode _toFileNode(
    SiteApi api,
    FsEntry entry, {
    required String parentPath,
  }) {
    final effectiveParent = entry.parent.isNotEmpty ? entry.parent : parentPath;
    final fullPath = NodeFolder.joinPath(effectiveParent, entry.name);
    final mediaUrl = entry.isDir
        ? null
        : _buildFileUrl(api, fullPath, entry.sign);

    return FileNode(
      type: _nodeTypeFor(entry),
      title: entry.name,
      size: entry.size,
      lastModified: entry.modified?.millisecondsSinceEpoch ?? 0,
      source: _sourceForSite(widget.siteId),
      workId: widget.work.id,
      siteId: widget.siteId,
      remoteId: fullPath,
      path: fullPath,
      folderPath: effectiveParent,
      mediaDownloadUrl: mediaUrl,
      mediaStreamUrl: mediaUrl,
    );
  }

  String? _buildFileUrl(SiteApi api, String path, String sign) {
    final baseUrl = api.httpClient?.dio.options.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) return null;
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final encodedPath = normalizedPath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    final uri = Uri.parse('$base/d$encodedPath');
    return sign.isEmpty
        ? uri.toString()
        : uri.replace(queryParameters: {'sign': sign}).toString();
  }

  NodeType _nodeTypeFor(FsEntry entry) {
    if (entry.isDir) return NodeType.folder;
    if (FileExtensions.isAudio(entry.name)) return NodeType.audio;
    if (FileExtensions.isVideo(entry.name)) return NodeType.video;
    if (FileExtensions.isImage(entry.name)) return NodeType.image;
    if (FileExtensions.isDocument(entry.name) ||
        FileExtensions.isSubtitle(entry.name)) {
      return NodeType.text;
    }
    return NodeType.other;
  }

  List<FileNode> _appendUnique(
    List<FileNode> current,
    List<FileNode> incoming,
  ) {
    final keys = current.map((node) => node.keyId).toSet();
    return [...current, ...incoming.where((node) => keys.add(node.keyId))];
  }
}

class _FileSystemBreadcrumbHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  _FileSystemBreadcrumbHeaderDelegate({
    required this.paths,
    required this.onHomeTap,
    required this.onPathTap,
    required this.onRefresh,
  });

  final List<String> paths;
  final VoidCallback onHomeTap;
  final ValueChanged<int> onPathTap;
  final VoidCallback onRefresh;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: BreadcrumbBar(
                paths: paths,
                onHomeTap: onHomeTap,
                onPathTap: onPathTap,
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
            ),
            IconButton(
              tooltip: '刷新当前来源',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(
    covariant _FileSystemBreadcrumbHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.paths != paths;
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
    this.onRefresh,
  });

  final FileNodeLibraryIndex index;
  final Work work;
  final bool isLocal;
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
            source: widget.isLocal
                ? NodeSource.localWork
                : NodeSource.asmrServer,
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

String _rjCodeFor(Work work) {
  for (final value in [work.originalWorkno, work.sourceId, work.sourceUrl]) {
    final match = RegExp(
      r'RJ0?\d{6,10}',
      caseSensitive: false,
    ).firstMatch(value ?? '');
    if (match != null) return match.group(0)!.toUpperCase();
  }
  return 'RJ0${work.id}';
}

int _rjNumberFor(Work work) {
  return _normalizedRjNumber(_rjCodeFor(work)) ?? work.id;
}

bool _containsRj(String value, String rjCode) {
  final expected = _normalizedRjNumber(rjCode);
  if (expected == null) return false;
  return RegExp(r'RJ0?(\d{6,10})', caseSensitive: false)
      .allMatches(value)
      .map((match) => int.tryParse(match.group(1)!))
      .contains(expected);
}

int? _normalizedRjNumber(String value) {
  final match = RegExp(
    r'RJ0?(\d{6,10})',
    caseSensitive: false,
  ).firstMatch(value);
  return match == null ? null : int.tryParse(match.group(1)!);
}

NodeSource _sourceForSite(String siteId) {
  return siteId == 'asmr.gay' ? NodeSource.asmrGay : NodeSource.cloudDrive;
}
