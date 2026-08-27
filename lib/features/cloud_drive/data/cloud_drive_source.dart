import 'package:kikoenai_core/kikoenai_core.dart';

import '../model/cloud_drive_page_result.dart';

abstract interface class CloudDriveSource {
  String get id;
  String get label;
  NodeSource get nodeSource;
  bool get supportsRemoteSearch;
  bool get supportsPagination;

  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  });

  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  });

  String describeError(Object error);
}
