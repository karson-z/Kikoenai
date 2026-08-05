import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../../core/service/site/site_api_provider.dart';

final localWorkFileIndexProvider = Provider.family<FileNodeLibraryIndex?, int>((
  ref,
  workId,
) {
  return FileScannerStorage().getWorkFileIndexLocally(workId);
});

/// Registered runtimes that can contribute media to a work detail page.
///
/// A site either exposes a work track tree, or the pair of file-system
/// capabilities needed to locate an RJ code and browse the matched directory.
final albumMediaSiteRuntimesProvider = Provider<List<SiteRuntime>>((ref) {
  ref.watch(siteRegistryChangesProvider);
  final registry = ref.watch(siteRegistryProvider);
  return List.unmodifiable(
    registry.allRuntimes.where((runtime) {
      final api = runtime.api;
      return api.supports(SiteFeature.tracks) ||
          (api.supports(SiteFeature.fileSystemSearch) &&
              api.supports(SiteFeature.fileSystemBrowse));
    }),
  );
});

final trackFileNodeIndexProvider =
    FutureProvider.family<FileNodeLibraryIndex, SiteContentId>((
      ref,
      contentId,
    ) async {
      final api = ref.watch(siteApiByIdProvider(contentId.siteId));
      if (!api.supports(SiteFeature.tracks)) {
        throw UnsupportedError('站点 ${contentId.siteId} 不支持作品音轨');
      }
      final nodes = await api.getWorkTracks(contentId.remoteId);
      const currentSource = NodeSource.asmrServer;

      return FileNodeLibraryIndex.fromRemoteTree(
        roots: nodes,
        contentId: contentId,
        source: currentSource,
      );
    });

final trackFileNodeProvider =
    FutureProvider.family<List<FileNode>, SiteContentId>((
      ref,
      contentId,
    ) async {
      final index = await ref.watch(
        trackFileNodeIndexProvider(contentId).future,
      );
      return index.toTreeChildren();
    });
final workDetailProvider = FutureProvider.family
    .autoDispose<Work?, SiteContentId>((ref, contentId) async {
      final api = ref.watch(siteApiByIdProvider(contentId.siteId));
      if (!api.supports(SiteFeature.detail)) return null;
      final work = await api.getWorkDetail(contentId.remoteId);
      return work;
    });
