import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/data/service/work_repository.dart';

final trackFileNodeProvider = FutureProvider.family<List<FileNode>, int>((ref, workId) async {
  final repo = ref.read(workRepositoryProvider);

  final response = await repo.getWorkTracks(workId);

  final data = response.data;

  if (data == null) return [];

  // JSON 解析
  final nodes = data
      .map<FileNode>((json) => FileNode.fromJson(json as Map<String, dynamic>))
      .toList();

  return nodes;
});
final workDetailProvider = FutureProvider.family<Work,int>((ref,workId) async {
  final repo = ref.read(workRepositoryProvider);
  final response = await repo.getWorkDetail(workId);
  final workJson = response.data;
  if(workJson == null){
    return Work();
  }
  final work = Work.fromJson(workJson);
  return work;
});