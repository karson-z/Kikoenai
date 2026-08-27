import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/service/site/site_api_setup.dart' as site_setup;
import 'package:kikoenai_sites/kikoenai_sites.dart';

final selfHostedSiteServersProvider = Provider<List<ServerInfo>>((ref) {
  ref.watch(siteRegistryChangesProvider);
  return List<ServerInfo>.unmodifiable(
    ref.watch(siteRegistryProvider).serversOf(KikoeruSiteApi.info.id),
  );
});

class SelfHostedSiteController {
  const SelfHostedSiteController(this.ref);

  final Ref ref;

  Future<void> addAndActivate(ServerInfo server) async {
    final servers = [...ref.read(selfHostedSiteServersProvider), server];
    await site_setup.updateSiteServers(KikoeruSiteApi.info.id, servers);
    await site_setup.switchServer(server.id, siteId: KikoeruSiteApi.info.id);
    await ref
        .read(activeSiteIdProvider.notifier)
        .activate(KikoeruSiteApi.info.id);
  }
}

final selfHostedSiteControllerProvider = Provider<SelfHostedSiteController>(
  SelfHostedSiteController.new,
);
