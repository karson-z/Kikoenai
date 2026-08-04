import '../network/http_client.dart';
import 'server_info.dart';
import 'site_api.dart';
import 'site_feature.dart';
import 'site_info.dart';
import 'site_plugin.dart';

/// Long-lived, isolated runtime state for one registered site.
class SiteRuntime {
  SiteRuntime._({
    required this.plugin,
    required this.info,
    required this.api,
    required this.httpClient,
  });

  factory SiteRuntime.create(
    SitePlugin plugin, {
    SiteRuntimeContext context = const SiteRuntimeContext(),
  }) {
    final info = context.resolveInfo(plugin.info);
    final api = plugin.createApi(context);
    return SiteRuntime._(
      plugin: plugin,
      info: info,
      api: api,
      httpClient: api.httpClient,
    );
  }

  factory SiteRuntime.fromApi({
    required SiteInfo info,
    required SiteApi api,
    SitesHttpClient? httpClient,
  }) {
    return SiteRuntime._(
      plugin: SitePlugin(info: info, createApi: (_) => api),
      info: info,
      api: api,
      httpClient: httpClient,
    );
  }

  final SitePlugin plugin;
  final SiteInfo info;
  final SiteApi api;
  final SitesHttpClient? httpClient;

  String get siteId => info.id;
  ServerInfo? get currentServer => info.servers.isEmpty
      ? null
      : api.supports(SiteFeature.serverSwitch)
      ? api.currentServer
      : info.defaultServer;

  void dispose() => httpClient?.close();
}
