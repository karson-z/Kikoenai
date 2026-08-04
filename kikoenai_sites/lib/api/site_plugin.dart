import '../network/exception.dart';
import '../network/http_client.dart';
import 'server_info.dart';
import 'site_api.dart';
import 'site_info.dart';

typedef SiteApiFactory = SiteApi Function(SiteRuntimeContext context);

/// Static site metadata plus the factory used to create its runtime API.
class SitePlugin {
  const SitePlugin({required this.info, required this.createApi});

  final SiteInfo info;
  final SiteApiFactory createApi;
}

typedef SiteInitialServerResolver = ServerInfo? Function(SiteInfo info);
typedef SiteServersResolver = List<ServerInfo> Function(SiteInfo info);
typedef SiteTokenResolver = Future<String?> Function(String siteId);
typedef SiteReadRecovery =
    Future<ReadRecoveryResult> Function(
      String siteId,
      SitesNetworkException exception,
    );
typedef SiteUnauthorizedHandler = void Function(String siteId);

/// Host capabilities supplied by the app when a site runtime is created.
///
/// The plugin remains responsible for its site-specific HTTP configuration;
/// the host only supplies persistence, authentication, and recovery hooks.
class SiteRuntimeContext {
  const SiteRuntimeContext({
    this.serversFor,
    this.initialServerFor,
    this.tokenFor,
    this.recoverReadRequest,
    this.onUnauthorized,
  });

  /// Resolves the effective server list for a site at runtime.
  ///
  /// Built-in sites fall back to [SiteInfo.servers]. A host can inject a
  /// persisted list for a self-hosted site without registering one plugin per
  /// user-entered domain.
  final SiteServersResolver? serversFor;
  final SiteInitialServerResolver? initialServerFor;
  final SiteTokenResolver? tokenFor;
  final SiteReadRecovery? recoverReadRequest;
  final SiteUnauthorizedHandler? onUnauthorized;

  List<ServerInfo> resolveServers(SiteInfo info) =>
      List<ServerInfo>.unmodifiable(serversFor?.call(info) ?? info.servers);

  SiteInfo resolveInfo(SiteInfo info) =>
      info.copyWith(servers: resolveServers(info));

  ServerInfo? resolveInitialServer(SiteInfo info) {
    final runtimeInfo = resolveInfo(info);
    return initialServerFor?.call(runtimeInfo) ?? runtimeInfo.defaultServer;
  }
}
