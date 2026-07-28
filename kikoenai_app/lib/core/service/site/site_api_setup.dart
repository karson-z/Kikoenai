import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

final SiteRegistry siteRegistry = SiteRegistry();

String _initialActiveSiteId = CacheService.legacySiteId;

String get initialActiveSiteId => _initialActiveSiteId;

/// Compatibility access for startup logging and callers not yet under Riverpod.
SiteApi get siteApi {
  final persistedId = CacheService.instance.getActiveSiteId();
  final siteId = persistedId != null && siteRegistry.contains(persistedId)
      ? persistedId
      : _initialActiveSiteId;
  return siteRegistry.requireApi(siteId);
}

Future<void> setupSiteApi() async {
  final cache = CacheService.instance;
  await cache.migrateLegacySiteData();

  siteRegistry.clear();
  SiteManager.instance.clear();

  await _registerAsmrOne(cache);

  final cachedActiveId = cache.getActiveSiteId();
  _initialActiveSiteId =
      cachedActiveId != null && siteRegistry.contains(cachedActiveId)
      ? cachedActiveId
      : siteRegistry.allInfo.first.id;
  await cache.saveActiveSiteId(_initialActiveSiteId);
  SiteManager.instance.activeId = _initialActiveSiteId;

  try {
    final results = await SiteManager.instance.bootstrapHealthyServers();
    for (final entry in results.entries) {
      final selected = entry.value;
      if (selected != null) {
        await cache.saveCurrentHost(selected.baseUrl, siteId: entry.key);
      }
    }
  } catch (error) {
    debugPrint('健康检查失败，使用各站点默认服务器: $error');
  }
}

Future<void> _registerAsmrOne(CacheService cache) async {
  const siteId = CacheService.legacySiteId;
  final cachedHost = cache.getCurrentHost(siteId: siteId);
  ServerInfo? initialServer;
  if (cachedHost != null && cachedHost.isNotEmpty) {
    final matched = AsmrOneSiteApi.info.servers.where(
      (server) =>
          cachedHost.contains(server.id) || server.baseUrl.contains(cachedHost),
    );
    if (matched.isNotEmpty) initialServer = matched.first;
  }

  final httpClient = SitesHttpClient(
    config: RequestConfig(
      baseUrl:
          initialServer?.baseUrl ?? AsmrOneSiteApi.info.defaultServer!.baseUrl,
      enableLogger: true,
      enableCookie: true,
      onUnauthorized: (request) => _handleUnauthorized(siteId, request),
    ),
    tokenProvider: () async {
      return cache.getAuthSession(siteId: siteId)?.token;
    },
  );

  final runtime = siteRegistry.register(
    AsmrOneSiteApi.plugin,
    context: SiteRuntimeContext(
      httpClient: httpClient,
      initialServer: initialServer ?? AsmrOneSiteApi.info.defaultServer,
    ),
  );

  // Keep the public package manager operational for existing integrations.
  SiteManager.instance.register(info: runtime.info, api: runtime.api);
}

void _handleUnauthorized(String siteId, RequestOptions requestOptions) {
  if (CacheService.instance.getActiveSiteId() != siteId) return;
  final context = AppConstants.rootNavigatorKey.currentContext;
  if (context == null) return;

  KikoenaiToast.error(
    '登录已过期，请重新登录',
    context: context,
    action: SnackBarAction(
      label: '去登录',
      textColor: Colors.white,
      onPressed: () => context.push(AppRoutes.login),
    ),
  );
}

Future<void> switchServer(String serverId, {String? siteId}) async {
  final targetSiteId =
      siteId ?? CacheService.instance.getActiveSiteId() ?? _initialActiveSiteId;
  final runtime = siteRegistry.requireRuntime(targetSiteId);
  final server = runtime.info.servers.firstWhere(
    (candidate) => candidate.id == serverId,
    orElse: () => throw ArgumentError('站点 $targetSiteId 不存在服务器 $serverId'),
  );
  await runtime.api.switchServer(server);
  await CacheService.instance.saveCurrentHost(
    server.baseUrl,
    siteId: targetSiteId,
  );
}
