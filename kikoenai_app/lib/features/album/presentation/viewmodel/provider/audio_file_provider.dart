import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/core/model/local_media/file_node.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai_core/core/model/album/work.dart';
import 'package:kikoenai/features/album/data/service/work_repository.dart';

final trackFileNodeIndexProvider =
    FutureProvider.family<FileNodeLibraryIndex, int>((ref, workId) async {
      final repo = ref.read(workRepositoryProvider);
      final response = await repo.getWorkTracks(workId);
      const currentSource = NodeSource.asmrServer;

      final nodes = response.map<FileNode>((json) {
        final baseNode = FileNode.fromJson(json as Map<String, dynamic>);
        return baseNode.copyWith(source: currentSource);
      }).toList();

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
  final repo = ref.read(workRepositoryProvider);

  final response = await repo.getWorkDetail(workId);
  return Work.fromJson(response);
});
