import 'package:kikoenai_core/kikoenai_core.dart';

import 'scraper_controller.dart';
import 'scraper_storage.dart';

final _rjCode = RegExp(
  r'(?:^|[^A-Za-z0-9])RJ0?(\d{7,9})(?!\d)',
  caseSensitive: false,
);

String browserSelectionKey(FileNode node) =>
    node.path ?? node.remoteId ?? node.mediaStreamUrl ?? node.keyId;

int? workIdForSelection(FileNode node) {
  if (node.isFolder) {
    final match = _rjCode.firstMatch(node.title);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
  final match =
      _rjCode.firstMatch(node.title) ?? _rjCode.firstMatch(node.path ?? '');
  return match == null ? null : int.tryParse(match.group(1)!);
}

List<FileNode> eligibleScraperNodes(
  Iterable<FileNode> nodes,
  ScraperQueueState queue, {
  bool Function(int workId)? hasWork,
}) {
  final exists = hasWork ?? ScraperStorage().hasWork;
  final busyIds = <int>{
    for (final node in [...queue.pending, ...queue.processing, ...queue.paused])
      if (node.workId != null) node.workId!,
  };
  final selectedIds = <int>{};
  return [
    for (final node in nodes)
      if (workIdForSelection(node) case final int id)
        if (!exists(id) && !busyIds.contains(id) && selectedIds.add(id))
          node.copyWith(workId: id, nodeStatus: NodeStatus.pending),
  ];
}
