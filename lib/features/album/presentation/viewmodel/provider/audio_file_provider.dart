import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/data/service/work_repository.dart';

final trackFileNodeProvider = FutureProvider.family<List<FileNode>, int>((ref, workId) async {
  final repo = ref.read(workRepositoryProvider);
  final response = await repo.getWorkTracks(workId);
  const currentSource = NodeSource.asmrServer;

  final nodes = response.map<FileNode>((json) {
    final baseNode = FileNode.fromJson(json as Map<String, dynamic>);
    return baseNode.copyWith(
      source: currentSource,
    );
  }).toList();
  return nodes;
});
final workDetailProvider =
FutureProvider.family.autoDispose<Work?, int>(
      (ref, workId) async {
    final repo = ref.read(workRepositoryProvider);

    final response = await repo.getWorkDetail(workId);
    return Work.fromJson(response);
  },
);
