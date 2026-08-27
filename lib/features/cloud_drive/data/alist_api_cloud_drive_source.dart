import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../model/cloud_drive_page_result.dart';
import 'cloud_drive_source.dart';

class AlistApiCloudDriveSource implements CloudDriveSource {
  const AlistApiCloudDriveSource(this.api);

  final AlistSiteApi api;

  @override
  String get id => api.siteInfo.id;

  @override
  String get label => api.siteInfo.name;

  @override
  NodeSource get nodeSource => api.fileNodeSource;

  @override
  bool get supportsPagination => true;

  @override
  bool get supportsRemoteSearch => true;

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    final result = await api.browseAsFileNodes(
      FsListRequest(path: path, page: page, perPage: pageSize),
    );
    return CloudDrivePageResult(
      items: result.items,
      totalCount: result.pagination.totalCount,
    );
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) async {
    final result = await api.searchAsFileNodes(
      FsSearchRequest(
        parent: path,
        keywords: query,
        scope: scope,
        page: page,
        perPage: pageSize,
      ),
    );
    return CloudDrivePageResult(
      items: result.items,
      totalCount: result.pagination.totalCount,
    );
  }

  @override
  String describeError(Object error) => '请求失败，请检查网络连接后重试';
}
