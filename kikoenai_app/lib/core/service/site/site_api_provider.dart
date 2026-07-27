import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import 'site_api_setup.dart';

/// AsmrOneSiteApi 的 Riverpod Provider。
///
/// 业务层通过 `ref.read(siteApiProvider)` 获取 [AsmrOneSiteApi] 实例，
/// 直接调用强类型方法，无需经过 Repository 中间层。
///
/// 实例在 `main()` 中通过 [setupSiteApi] 初始化，此处仅做暴露。
final siteApiProvider = Provider<AsmrOneSiteApi>((ref) {
  return siteApi;
});

/// SitesHttpClient 的 Riverpod Provider（供需要直接 getBytes 的场景使用）。
final sitesHttpClientProvider = Provider<SitesHttpClient>((ref) {
  return siteApi.httpClient;
});
