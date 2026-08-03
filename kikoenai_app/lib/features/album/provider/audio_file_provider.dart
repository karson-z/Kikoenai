import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../../core/service/site/site_api_provider.dart';

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
