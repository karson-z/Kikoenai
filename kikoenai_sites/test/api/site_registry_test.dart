import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeSiteApi extends SiteApi {
  _FakeSiteApi(this.features);

  final Set<SiteFeature> features;

  @override
  Set<SiteFeature> get supportedFeatures => features;
}

class _FakeServerApi extends SiteApi {
  _FakeServerApi(this._currentServer, this.healthyServerIds);

  ServerInfo _currentServer;
  final Set<String> healthyServerIds;

  @override
  Set<SiteFeature> get supportedFeatures => const {
        SiteFeature.serverSwitch,
        SiteFeature.healthCheck,
      };

  @override
  ServerInfo get currentServer => _currentServer;

  @override
  Future<void> switchServer(ServerInfo server) async {
    _currentServer = server;
  }

  @override
  Future<ServerHealth> checkHealth(ServerInfo server) async {
    return ServerHealth(
      serverId: server.id,
      status: healthyServerIds.contains(server.id)
          ? HealthStatus.healthy
          : HealthStatus.unhealthy,
      checkedAt: DateTime.now(),
    );
  }
}

const _defaultServer = ServerInfo(
  id: 'default',
  baseUrl: 'https://default.example/api',
  label: 'Default',
  isDefault: true,
);

const _backupServer = ServerInfo(
  id: 'backup',
  baseUrl: 'https://backup.example/api',
  label: 'Backup',
);

SitePlugin _plugin(String id, Set<SiteFeature> features) {
  return SitePlugin(
    info: SiteInfo(id: id, name: id, version: '1.0.0'),
    createApi: (_) => _FakeSiteApi(features),
  );
}

void main() {
  group('SiteRegistry', () {
    test('registers all built-in sites with isolated HTTP clients', () {
      final resolvedSiteIds = <String>[];
      final registry = SiteRegistry();
      addTearDown(registry.clear);

      final context = SiteRuntimeContext(
        initialServerFor: (info) {
          resolvedSiteIds.add(info.id);
          return info.defaultServer;
        },
      );
      for (final plugin in builtInSitePlugins) {
        registry.register(plugin, context: context);
      }

      expect(
        registry.allInfo.map((info) => info.id),
        ['asmr.one', 'asmr.gay'],
      );
      expect(resolvedSiteIds, ['asmr.one', 'asmr.gay']);

      final asmrOne = registry.requireRuntime('asmr.one');
      final asmrGay = registry.requireRuntime('asmr.gay');
      expect(asmrOne.httpClient, isNotNull);
      expect(asmrGay.httpClient, isNotNull);
      expect(asmrOne.httpClient, isNot(same(asmrGay.httpClient)));
      expect(
        asmrOne.httpClient!.dio.options.baseUrl,
        AsmrOneSiteApi.info.defaultServer!.baseUrl,
      );
      expect(
        asmrGay.httpClient!.dio.options.baseUrl,
        AsmrGaySiteApi.info.defaultServer!.baseUrl,
      );
    });

    test('keeps independent runtimes for multiple sites', () {
      final registry = SiteRegistry();
      registry.register(_plugin('site.one', {SiteFeature.search}));
      registry.register(_plugin('site.two', {SiteFeature.detail}));

      expect(registry.allInfo.map((info) => info.id), ['site.one', 'site.two']);
      expect(registry.supports('site.one', SiteFeature.search), isTrue);
      expect(registry.supports('site.one', SiteFeature.detail), isFalse);
      expect(registry.supports('site.two', SiteFeature.detail), isTrue);
      expect(
        registry.requireApi('site.one'),
        isNot(same(registry.requireApi('site.two'))),
      );
      expect(registry.activeId, 'site.one');
      expect(registry.activeInfo?.id, 'site.one');

      registry.activeId = 'site.two';
      expect(registry.activeApi, same(registry.requireApi('site.two')));

      registry.unregister('site.two');
      expect(registry.activeId, 'site.one');
    });

    test('rejects duplicate IDs and unknown runtime lookups', () {
      final registry = SiteRegistry();
      registry.register(_plugin('site.one', const {}));

      expect(
        () => registry.register(_plugin('site.one', const {})),
        throwsStateError,
      );
      expect(() => registry.requireRuntime('missing'), throwsStateError);
      expect(() => registry.activeId = 'missing', throwsStateError);
    });

    test('manages server switching and healthy server selection', () async {
      final api = _FakeServerApi(_defaultServer, {'backup'});
      final registry = SiteRegistry()
        ..register(
          SitePlugin(
            info: const SiteInfo(
              id: 'site.servers',
              name: 'Server site',
              version: '1.0.0',
              servers: [_defaultServer, _backupServer],
            ),
            createApi: (_) => api,
          ),
        );

      expect(registry.currentServerOf('site.servers'), _defaultServer);
      expect(await registry.checkAllServerHealth('site.servers'), hasLength(2));

      final selected = await registry.selectHealthyServer('site.servers');
      expect(selected, _backupServer);
      expect(registry.currentServerOf('site.servers'), _backupServer);

      await registry.switchServer('site.servers', 'default');
      expect(registry.currentServerOf('site.servers'), _defaultServer);

      final fallback = await registry.selectHealthyServer(
        'site.servers',
        excludedServerIds: {'default'},
      );
      expect(fallback, _backupServer);
      expect(registry.currentServerOf('site.servers'), _backupServer);

      expect(
        () => registry.switchServer('site.servers', 'missing'),
        throwsArgumentError,
      );
    });
  });
}
