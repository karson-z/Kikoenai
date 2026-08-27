import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import 'site_unavailable_controller.dart';

final SiteRegistry siteRegistry = SiteRegistry();

const _readFailoverCooldown = Duration(seconds: 30);
final Map<String, Future<ReadRecoveryResult>> _readFailoversInFlight = {};
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
  siteUnavailableController.clear();

  final runtimeContext = _createRuntimeContext(cache);
  siteRegistry.registerAvailable(builtInSitePlugins, context: runtimeContext);

  if (siteRegistry.allInfo.isEmpty) {
    throw StateError('没有能够解析到服务器的站点');
  }

  final cachedActiveId = cache.getActiveSiteId();
  _initialActiveSiteId =
      cachedActiveId != null && siteRegistry.contains(cachedActiveId)
      ? cachedActiveId
      : siteRegistry.allInfo.first.id;
  await cache.saveActiveSiteId(_initialActiveSiteId);
  siteRegistry.activeId = _initialActiveSiteId;
}

SiteRuntimeContext _createRuntimeContext(
  CacheService cache, {
  Map<String, List<ServerInfo>> serverOverrides = const {},
}) {
  return SiteRuntimeContext(
    serversFor: (info) {
      final overridden = serverOverrides[info.id];
      final persisted = cache.getSiteServers(siteId: info.id);
      final resolved =
          overridden ?? (persisted.isEmpty ? info.servers : persisted);
      if (info.id == AsmrGaySiteApi.info.id) {
        final valid = resolved
            .where((server) {
              try {
                AsmrGaySiteApi.normalizeBaseUrl(server);
                return true;
              } catch (error) {
                debugPrint('忽略无效的 AList 服务器 ${server.id}: $error');
                return false;
              }
            })
            .toList(growable: false);
        return valid.isEmpty ? info.servers : valid;
      }
      if (info.id != KikoeruSiteApi.info.id) return resolved;
      return resolved
          .where((server) {
            try {
              KikoeruSiteApi.apiBaseUrlFor(server);
              return true;
            } catch (error) {
              debugPrint('忽略无效的 Kikoeru 服务器 ${server.id}: $error');
              return false;
            }
          })
          .toList(growable: false);
    },
    initialServerFor: (info) => _resolveInitialServer(info, cache),
    tokenFor: (siteId) async => cache.getAuthSession(siteId: siteId)?.token,
    recoverReadRequest: (siteId, exception) =>
        _recoverReadRequest(siteId: siteId, exception: exception),
    onUnauthorized: _handleUnauthorized,
  );
}

/// Persists a site's user-supplied servers and updates its runtime immediately.
///
/// Passing an empty list removes the user override. The site then falls back to
/// statically declared servers; if neither source provides a server, its
/// runtime is unregistered and disappears from the usable site list.
Future<SiteRuntime?> updateSiteServers(
  String siteId,
  List<ServerInfo> servers,
) async {
  final plugin = _findBuiltInPlugin(siteId);
  if (plugin == null) throw ArgumentError('未知站点: $siteId');

  _validateServerList(siteId, servers);
  final effectiveServers = servers.isEmpty ? plugin.info.servers : servers;
  final cache = CacheService.instance;
  final context = _createRuntimeContext(
    cache,
    serverOverrides: {siteId: effectiveServers},
  );
  final candidate = effectiveServers.isEmpty
      ? null
      : SiteRuntime.create(plugin, context: context);

  try {
    if (servers.isEmpty) {
      await cache.clearSiteServers(siteId: siteId);
    } else {
      await cache.saveSiteServers(servers, siteId: siteId);
    }
  } catch (_) {
    candidate?.dispose();
    rethrow;
  }

  final wasActive = siteRegistry.activeId == siteId;
  if (candidate == null) {
    siteRegistry.unregister(siteId);
  } else {
    siteRegistry.replaceRuntime(candidate);
    if (wasActive) siteRegistry.activeId = siteId;
    final currentServer = candidate.currentServer;
    if (currentServer != null) {
      await _persistSelectedServer(siteId, currentServer);
    }
  }

  final activeId = siteRegistry.activeId;
  if (wasActive && activeId != null) {
    _initialActiveSiteId = activeId;
    await cache.saveActiveSiteId(activeId);
  }
  _clearReadFailoverState(siteId);
  return candidate;
}

SitePlugin? _findBuiltInPlugin(String siteId) {
  for (final plugin in builtInSitePlugins) {
    if (plugin.info.id == siteId) return plugin;
  }
  return null;
}

void _validateServerList(String siteId, List<ServerInfo> servers) {
  final ids = <String>{};
  final baseUrls = <String>{};
  for (final server in servers) {
    if (server.id.trim().isEmpty) {
      throw ArgumentError('站点 $siteId 的服务器 ID 不能为空');
    }
    if (!ids.add(server.id)) {
      throw ArgumentError('站点 $siteId 存在重复服务器 ID: ${server.id}');
    }
    if (siteId == KikoeruSiteApi.info.id) {
      KikoeruSiteApi.apiBaseUrlFor(server);
    }
    if (siteId == AsmrGaySiteApi.info.id) {
      final baseUrl = AsmrGaySiteApi.normalizeBaseUrl(server);
      if (!baseUrls.add(baseUrl.toLowerCase())) {
        throw ArgumentError('AList 存在重复地址: $baseUrl');
      }
    }
  }
}

ServerInfo? _resolveInitialServer(SiteInfo info, CacheService cache) {
  final cachedHost = cache.getCurrentHost(siteId: info.id);
  if (cachedHost != null && cachedHost.isNotEmpty) {
    final matched = info.servers.where(
      (server) =>
          cachedHost.contains(server.id) ||
          server.resolvedBaseUrl.contains(cachedHost),
    );
    if (matched.isNotEmpty) return matched.first;
  }
  return info.defaultServer;
}

Future<ReadRecoveryResult> _recoverReadRequest({
  required String siteId,
  required SitesNetworkException exception,
}) async {
  final currentServer = siteRegistry.currentServerOf(siteId);
  if (currentServer == null) return const ReadRecoveryResult.skipped();

  final originalError = exception.originalError;
  final activeBaseUrl = siteRegistry
      .apiOf(siteId)
      ?.httpClient
      ?.dio
      .options
      .baseUrl;
  final failedBaseUrl = originalError is DioException
      ? originalError.requestOptions.baseUrl
      : activeBaseUrl ?? currentServer.resolvedBaseUrl;

  // Another request may already have completed recovery for this site.
  if (activeBaseUrl != null && activeBaseUrl != failedBaseUrl) {
    return const ReadRecoveryResult.recovered();
  }

  final recoveryKey = '$siteId::$failedBaseUrl';
  final inFlight = _readFailoversInFlight[recoveryKey];
  if (inFlight != null) return inFlight;

  final now = DateTime.now();
  final lastAttempt = _lastReadFailoverAttempt[recoveryKey];
  if (lastAttempt != null &&
      now.difference(lastAttempt) < _readFailoverCooldown) {
    return _allServersUnavailable(siteId);
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

Future<ReadRecoveryResult> _switchToHealthyAlternative({
  required String siteId,
  required String failedServerId,
}) async {
  ServerInfo? selected;
  try {
    selected = await siteRegistry.selectHealthyServer(
      siteId,
      excludedServerIds: {failedServerId},
    );
  } catch (error) {
    debugPrint('检查站点 $siteId 的备用服务器失败: $error');
  }
  if (selected == null) return _allServersUnavailable(siteId);

  await _persistSelectedServer(siteId, selected);
  return const ReadRecoveryResult.recovered();
}

ReadRecoveryResult _allServersUnavailable(String siteId) {
  final serverIds = siteRegistry
      .serversOf(siteId)
      .map((server) => server.id)
      .toList(growable: false);
  siteUnavailableController.report(siteId: siteId, serverIds: serverIds);
  return ReadRecoveryResult.allServersUnavailable(
    context: {'siteId': siteId, 'serverIds': serverIds},
  );
}

Future<ServerInfo?> recheckSiteServers(String siteId) async {
  ServerInfo? selected;
  try {
    selected = await siteRegistry.selectHealthyServer(siteId);
  } catch (error) {
    debugPrint('重新检查站点 $siteId 的服务器失败: $error');
  }
  if (selected == null) return null;

  await _persistSelectedServer(siteId, selected);
  _clearReadFailoverState(siteId);
  return selected;
}

Future<void> _persistSelectedServer(String siteId, ServerInfo server) async {
  try {
    await CacheService.instance.saveCurrentHost(
      server.resolvedBaseUrl,
      siteId: siteId,
    );
  } catch (error) {
    debugPrint('保存站点 $siteId 的服务器失败: $error');
  }
}

void _clearReadFailoverState(String siteId) {
  final prefix = '$siteId::';
  _readFailoversInFlight.removeWhere((key, _) => key.startsWith(prefix));
  _lastReadFailoverAttempt.removeWhere((key, _) => key.startsWith(prefix));
}

void _handleUnauthorized(String siteId) {
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
    server.resolvedBaseUrl,
    siteId: targetSiteId,
  );
  _clearReadFailoverState(targetSiteId);
}
