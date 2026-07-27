import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/core/model/local_media/file_node.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai_core/core/model/album/work.dart';
import '../../../../../core/service/site/site_api_provider.dart';

final trackFileNodeIndexProvider =
    FutureProvider.family<FileNodeLibraryIndex, int>((ref, workId) async {
      final api = ref.read(siteApiProvider);
      final nodes = await api.getWorkTracks(workId);
      const currentSource = NodeSource.asmrServer;

      return FileNodeLibraryIndex.fromRemoteTree(
        roots: nodes,
        workId: workId,
        source: currentSource,
      );
    });

final trackFileNodeProvider = FutureProvider.family<List<FileNode>, int>((
  ref,
  workId,
) async {
  final index = await ref.watch(trackFileNodeIndexProvider(workId).future);
  return index.toTreeChildren();
});
final workDetailProvider = FutureProvider.family.autoDispose<Work?, int>((
  ref,
  workId,
) async {
  final api = ref.read(siteApiProvider);
  final work = await api.getWorkDetail(workId);
  return work;
});
