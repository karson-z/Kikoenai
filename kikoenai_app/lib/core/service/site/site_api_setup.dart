import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

final SiteRegistry siteRegistry = SiteRegistry();

const _readFailoverCooldown = Duration(seconds: 30);
final Map<String, Future<bool>> _readFailoversInFlight = {};
final Map<String, DateTime> _lastReadFailoverAttempt = {};

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
  _readFailoversInFlight.clear();
  _lastReadFailoverAttempt.clear();

  _registerAsmrOne(cache);

  final cachedActiveId = cache.getActiveSiteId();
  _initialActiveSiteId =
      cachedActiveId != null && siteRegistry.contains(cachedActiveId)
      ? cachedActiveId
      : siteRegistry.allInfo.first.id;
  await cache.saveActiveSiteId(_initialActiveSiteId);
  siteRegistry.activeId = _initialActiveSiteId;
}

void _registerAsmrOne(CacheService cache) {
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
    readRequestRecovery: (exception) =>
        _recoverReadRequest(siteId: siteId, exception: exception),
  );

  siteRegistry.register(
    AsmrOneSiteApi.plugin,
    context: SiteRuntimeContext(
      httpClient: httpClient,
      initialServer: initialServer ?? AsmrOneSiteApi.info.defaultServer,
    ),
  );
}

Future<bool> _recoverReadRequest({
  required String siteId,
  required SitesNetworkException exception,
}) async {
  final currentServer = siteRegistry.currentServerOf(siteId);
  if (currentServer == null) return false;

  final originalError = exception.originalError;
  final failedBaseUrl = originalError is DioException
      ? originalError.requestOptions.baseUrl
      : currentServer.baseUrl;

  // Another request may already have completed recovery for this site.
  if (currentServer.baseUrl != failedBaseUrl) return true;

  final recoveryKey = '$siteId::$failedBaseUrl';
  final inFlight = _readFailoversInFlight[recoveryKey];
  if (inFlight != null) return inFlight;

  final now = DateTime.now();
  final lastAttempt = _lastReadFailoverAttempt[recoveryKey];
  if (lastAttempt != null &&
      now.difference(lastAttempt) < _readFailoverCooldown) {
    return false;
  }
  _lastReadFailoverAttempt[recoveryKey] = now;

  final recovery = _switchToHealthyAlternative(
    siteId: siteId,
    failedServerId: currentServer.id,
  );
  _readFailoversInFlight[recoveryKey] = recovery;
  try {
    return await recovery;
  } finally {
    if (identical(_readFailoversInFlight[recoveryKey], recovery)) {
      _readFailoversInFlight.remove(recoveryKey);
    }
  }
}

Future<bool> _switchToHealthyAlternative({
  required String siteId,
  required String failedServerId,
}) async {
  final selected = await siteRegistry.selectHealthyServer(
    siteId,
    excludedServerIds: {failedServerId},
  );
  if (selected == null) return false;

  try {
    await CacheService.instance.saveCurrentHost(
      selected.baseUrl,
      siteId: siteId,
    );
  } catch (error) {
    debugPrint('保存站点 $siteId 的故障切换服务器失败: $error');
  }
  return true;
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
  await siteRegistry.switchServer(targetSiteId, serverId);
  final server = siteRegistry.currentServerOf(targetSiteId)!;
  await CacheService.instance.saveCurrentHost(
    server.baseUrl,
    siteId: targetSiteId,
  );
}
