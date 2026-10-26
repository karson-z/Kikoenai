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
  String describeError(Object error) {
    if (error is SitesNetworkException) {
      final status = error.context?['status'] ?? error.context?['code'];
      if (status == 401 || error.code == SitesExceptionCode.unauthorized) {
        return 'AList 认证失效，请检查来源配置后重试';
      }
      if (status == 403 || error.code == SitesExceptionCode.forbidden) {
        return '没有访问此 AList 目录的权限';
      }
      if (status == 404 || error.code == SitesExceptionCode.notFound) {
        return 'AList 目录不存在，可能已移动或删除，可返回上级目录';
      }
      if (error.code == SitesExceptionCode.networkError) {
        return 'AList 连接失败或超时，请检查网络后重试';
      }
      return 'AList 目录读取失败，请检查路径与访问权限后重试';
    }
    return '请求失败，请检查网络连接后重试';
  }
}
