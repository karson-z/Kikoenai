import 'package:kikoenai_core/kikoenai_core.dart';

import '../model/cloud_drive_page_result.dart';
import '../provider/webdav_connection_controller.dart';
import 'cloud_drive_source.dart';

class WebDavCloudDriveSource implements CloudDriveSource {
  const WebDavCloudDriveSource(this.controller);

  final WebDavController controller;

  @override
  String get id => webDavSiteId;

  @override
  String get label => 'WebDAV';

  @override
  NodeSource get nodeSource => NodeSource.cloudDrive;

  @override
  bool get supportsPagination => false;

  @override
  bool get supportsRemoteSearch => false;

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    final items = await controller.listDirectory(path);
    return CloudDrivePageResult(items: items, totalCount: items.length);
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) async {
    final items = await controller.listDirectory(path);
    final normalizedQuery = query.trim().toLowerCase();
    final matches = items
        .where((node) {
          final matchesScope = switch (scope) {
            1 => node.isFolder,
            2 => !node.isFolder,
            _ => true,
          };
          return matchesScope &&
              node.title.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    return CloudDrivePageResult(items: matches, totalCount: matches.length);
  }

  @override
  String describeError(Object error) => WebDavController.describeError(error);
}
