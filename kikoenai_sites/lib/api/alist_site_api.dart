import 'package:kikoenai_core/kikoenai_core.dart';

import 'site_api.dart';
import 'site_info.dart';

/// Shared contract for AList-compatible Sites implementations.
abstract class AlistSiteApi extends SiteApi {
  SiteInfo get siteInfo;

  NodeSource get fileNodeSource;

  Future<PagedResult<FileNode>> browseAsFileNodes(FsListRequest request);

  Future<PagedResult<FileNode>> searchAsFileNodes(FsSearchRequest request);
}
