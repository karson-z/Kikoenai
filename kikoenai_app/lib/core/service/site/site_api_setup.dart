import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

/// 全局站点 API 初始化。
///
/// 在 `main()` 中调用 [setupSiteApi]，完成：
/// 1. 创建 [SitesHttpClient]，注入 tokenProvider / onUnauthorized
/// 2. 创建 [AsmrOneSiteApi]
/// 3. 注册到 [SiteManager]
/// 4. 启动健康检查，自动选择健康服务器
///
/// 初始化后业务层通过 [siteApi] 获取 [AsmrOneSiteApi] 实例。
///

/// 全局 AsmrOneSiteApi 实例（setupSiteApi 后非 null）
AsmrOneSiteApi? _siteApi;

/// 获取全局 AsmrOneSiteApi 实例。
///
/// 必须在 [setupSiteApi] 完成后调用。
AsmrOneSiteApi get siteApi {
  final api = _siteApi;
  if (api == null) {
    throw StateError('siteApi 尚未初始化，请先调用 setupSiteApi()');
  }
  return api;
}

/// 初始化站点 API。
///
/// 在 `main()` 中 `runApp` 之前调用：
///
/// ```dart
/// await setupSiteApi();
/// runApp(const ProviderScope(child: MyApp()));
/// ```
Future<void> setupSiteApi() async {
  // 1. 从缓存恢复上次选中的服务器
  final cachedHost = CacheService.instance.getCurrentHost();
  ServerInfo? initialServer;
  if (cachedHost != null && cachedHost.isNotEmpty) {
    final matched = AsmrOneSiteApi.info.servers
        .where((s) => cachedHost.contains(s.id) || s.baseUrl.contains(cachedHost))
        .toList();
    if (matched.isNotEmpty) initialServer = matched.first;
  }

  // 2. 创建 HTTP client，注入 tokenProvider 和 401 处理
  final httpClient = SitesHttpClient(
    config: RequestConfig(
      baseUrl: initialServer?.baseUrl ??
          AsmrOneSiteApi.info.defaultServer!.baseUrl,
      enableLogger: true,
      enableCookie: true,
      onUnauthorized: _handleUnauthorized,
    ),
    tokenProvider: () async {
      final session = CacheService.instance.getAuthSession();
      return session?.token;
    },
  );

  // 3. 创建站点 API
  final api = AsmrOneSiteApi(
    httpClient: httpClient,
    initialServer: initialServer ?? AsmrOneSiteApi.info.defaultServer!,
  );
  _siteApi = api;

  // 4. 注册到 SiteManager
  SiteManager.instance.clear();
  SiteManager.instance.register(info: AsmrOneSiteApi.info, api: api);

  // 5. 启动健康检查，自动选择健康服务器
  try {
    final results = await SiteManager.instance.bootstrapHealthyServers();
    final selected = results['asmr.one'];
    if (selected != null) {
      // 持久化选中的服务器
      await CacheService.instance.saveCurrentHost(selected.baseUrl);
    }
  } catch (e) {
    // 健康检查失败不阻塞启动，使用默认服务器
    debugPrint('健康检查失败，使用默认服务器: $e');
  }
}

/// 401 未授权处理：弹出 toast 并跳转登录页
void _handleUnauthorized(RequestOptions requestOptions) {
  final context = AppConstants.rootNavigatorKey.currentContext;
  if (context != null) {
    KikoenaiToast.error(
      '登录已过期，请重新登录',
      context: context,
      action: SnackBarAction(
        label: '去登录',
        textColor: Colors.white,
        onPressed: () {
          context.push(AppRoutes.login);
        },
      ),
    );
  }
}

/// 手动切换服务器（供设置页调用）。
///
/// 切换后持久化到缓存，并更新全局状态。
Future<void> switchServer(String serverId) async {
  final server = AsmrOneSiteApi.info.servers
      .firstWhere((s) => s.id == serverId);
  await siteApi.switchServer(server);
  await CacheService.instance.saveCurrentHost(server.baseUrl);
}
