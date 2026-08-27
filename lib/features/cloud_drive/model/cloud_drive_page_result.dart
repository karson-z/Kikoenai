import 'package:kikoenai_core/kikoenai_core.dart';

class CloudDrivePageResult {
  const CloudDrivePageResult({required this.items, required this.totalCount});

  final List<FileNode> items;
  final int totalCount;
}
