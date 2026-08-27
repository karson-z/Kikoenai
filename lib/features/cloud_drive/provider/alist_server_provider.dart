import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/service/site/site_api_setup.dart' as site_setup;
import 'package:kikoenai_sites/kikoenai_sites.dart';

class AlistServerState {
  const AlistServerState({required this.servers, required this.currentServer});

  final List<ServerInfo> servers;
  final ServerInfo currentServer;
}

final alistServerStateProvider = Provider<AlistServerState>((ref) {
  final runtime = ref.watch(siteRuntimeByIdProvider(AsmrGaySiteApi.info.id));
  return AlistServerState(
    servers: runtime.info.servers,
    currentServer: runtime.api.currentServer,
  );
});

class AlistServerController {
  const AlistServerController(this.ref);

  final Ref ref;

  Future<void> switchTo(String serverId) async {
    await site_setup.switchServer(serverId, siteId: AsmrGaySiteApi.info.id);
    ref.invalidate(siteRuntimeByIdProvider(AsmrGaySiteApi.info.id));
  }

  Future<void> upsert(ServerInfo server, {String? originalServerId}) async {
    final snapshot = ref.read(alistServerStateProvider);
    final servers = List<ServerInfo>.from(snapshot.servers);
    final existingIndex = originalServerId == null
        ? -1
        : servers.indexWhere((item) => item.id == originalServerId);
    if (existingIndex < 0) {
      servers.add(server);
    } else {
      servers[existingIndex] = server;
    }

    final shouldSelect =
        originalServerId == null ||
        snapshot.currentServer.id == originalServerId;
    await site_setup.updateSiteServers(AsmrGaySiteApi.info.id, servers);
    if (shouldSelect) await switchTo(server.id);
  }

  Future<void> remove(String serverId) async {
    final servers = ref
        .read(alistServerStateProvider)
        .servers
        .where((server) => server.id != serverId)
        .toList(growable: false);
    if (servers.isEmpty) {
      throw StateError('AList 至少需要保留一个域名');
    }
    await site_setup.updateSiteServers(AsmrGaySiteApi.info.id, servers);
    ref.invalidate(siteRuntimeByIdProvider(AsmrGaySiteApi.info.id));
  }

  Future<void> restoreBuiltInServers() async {
    await site_setup.updateSiteServers(AsmrGaySiteApi.info.id, const []);
    ref.invalidate(siteRuntimeByIdProvider(AsmrGaySiteApi.info.id));
  }
}

final alistServerControllerProvider = Provider<AlistServerController>(
  AlistServerController.new,
);
