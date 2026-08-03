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

/// Dependencies supplied by the app when a site runtime is created.
class SiteRuntimeContext {
  const SiteRuntimeContext({this.httpClient, this.initialServer});

  final SitesHttpClient? httpClient;
  final ServerInfo? initialServer;
}
