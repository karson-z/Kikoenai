import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/service/site/site_api_setup.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/cloud_drive/provider/alist_server_provider.dart';
import 'package:kikoenai/features/settings/widget/service_selection.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'kikoenai_server_cache_test_',
    );
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(TypeIds.serverInfo)) {
      Hive.registerAdapter(ServerInfoAdapter());
    }
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings_test');
    AppStorage.authBox = await Hive.openBox<AuthResponse>('auth_test');
  });

  tearDown(() async {
    siteRegistry.clear();
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('server lists are persisted independently for each site', () async {
    const server = ServerInfo(
      id: 'home',
      baseUrl: 'https://home.example/api',
      label: 'Home',
      port: 9443,
      useProxy: false,
      isDefault: true,
    );

    await CacheService.instance.saveSiteServers(const [
      server,
    ], siteId: 'self-hosted');

    expect(CacheService.instance.getSiteServers(siteId: 'self-hosted'), const [
      server,
    ]);
    expect(
      CacheService.instance.getSiteServers(siteId: 'another-site'),
      isEmpty,
    );

    await CacheService.instance.clearSiteServers(siteId: 'self-hosted');
    expect(
      CacheService.instance.getSiteServers(siteId: 'self-hosted'),
      isEmpty,
    );
  });

  test(
    'persisted Kikoeru servers are injected without changing static sites',
    () async {
      const server = ServerInfo(
        id: 'home-nas',
        baseUrl: 'https://nas.example.com/kikoeru',
        label: 'Home NAS',
        port: 9443,
        useProxy: false,
        isDefault: true,
      );
      await CacheService.instance.saveSiteServers(const [
        server,
      ], siteId: KikoeruSiteApi.info.id);

      await setupSiteApi();

      expect(siteRegistry.serversOf(KikoeruSiteApi.info.id), const [server]);
      expect(
        siteRegistry
            .requireRuntime(KikoeruSiteApi.info.id)
            .httpClient!
            .dio
            .options
            .baseUrl,
        'https://nas.example.com:9443/kikoeru/api',
      );
      expect(
        siteRegistry.serversOf(AsmrOneSiteApi.info.id),
        AsmrOneSiteApi.info.servers,
      );
    },
  );

  test('persisted AList domains use the shared Sites runtime', () async {
    const primary = ServerInfo(
      id: 'alist-primary',
      baseUrl: 'https://alist-primary.example',
      label: 'Primary AList',
      isDefault: true,
    );
    const backup = ServerInfo(
      id: 'alist-backup',
      baseUrl: 'https://alist-backup.example',
      label: 'Backup AList',
      useProxy: false,
    );
    await CacheService.instance.saveSiteServers(const [
      primary,
      backup,
    ], siteId: AsmrGaySiteApi.info.id);

    await setupSiteApi();

    final runtime = siteRegistry.requireRuntime(AsmrGaySiteApi.info.id);
    expect(runtime.info.servers, const [primary, backup]);
    expect(runtime.currentServer, primary);
    expect((runtime.api as AsmrGaySiteApi).rawBaseUrl, isNull);

    await switchServer(backup.id, siteId: AsmrGaySiteApi.info.id);
    expect(runtime.currentServer, backup);
    expect(
      CacheService.instance.getCurrentHost(siteId: AsmrGaySiteApi.info.id),
      backup.resolvedBaseUrl,
    );
  });

  test(
    'invalid persisted AList domains fall back to built-in servers',
    () async {
      await CacheService.instance.saveSiteServers(const [
        ServerInfo(
          id: 'invalid-alist',
          baseUrl: 'ftp://invalid.example.com',
          label: 'Invalid AList',
        ),
      ], siteId: AsmrGaySiteApi.info.id);

      await setupSiteApi();

      expect(
        siteRegistry.serversOf(AsmrGaySiteApi.info.id),
        AsmrGaySiteApi.info.servers,
      );
    },
  );

  test('AList server updates reject duplicate domains', () async {
    await setupSiteApi();

    expect(
      () => updateSiteServers(AsmrGaySiteApi.info.id, const [
        ServerInfo(
          id: 'first',
          baseUrl: 'https://alist.example.com/',
          label: 'First',
        ),
        ServerInfo(
          id: 'second',
          baseUrl: 'https://alist.example.com',
          label: 'Second',
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('cloud-drive AList controller adds and selects a domain', () async {
    await setupSiteApi();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const custom = ServerInfo(
      id: 'custom-alist',
      baseUrl: 'https://custom-alist.example',
      label: 'Custom AList',
      useProxy: false,
    );

    await container.read(alistServerControllerProvider).upsert(custom);

    expect(siteRegistry.serversOf(AsmrGaySiteApi.info.id), contains(custom));
    expect(siteRegistry.currentServerOf(AsmrGaySiteApi.info.id), custom);
    expect(
      CacheService.instance.getSiteServers(siteId: AsmrGaySiteApi.info.id),
      contains(custom),
    );
  });

  test(
    'Kikoeru is registered and unregistered immediately with user servers',
    () async {
      await setupSiteApi();
      expect(siteRegistry.contains(KikoeruSiteApi.info.id), isFalse);

      const server = ServerInfo(
        id: 'live-nas',
        baseUrl: 'https://live.example.com',
        label: 'Live NAS',
        port: 9443,
        useProxy: false,
        isDefault: true,
      );
      final revisionBeforeAdd = siteRegistry.revision;

      final runtime = await updateSiteServers(KikoeruSiteApi.info.id, const [
        server,
      ]);

      expect(runtime, isNotNull);
      expect(siteRegistry.contains(KikoeruSiteApi.info.id), isTrue);
      expect(siteRegistry.serversOf(KikoeruSiteApi.info.id), const [server]);
      expect(siteRegistry.revision, greaterThan(revisionBeforeAdd));

      final revisionBeforeRemove = siteRegistry.revision;
      await updateSiteServers(KikoeruSiteApi.info.id, const []);

      expect(siteRegistry.contains(KikoeruSiteApi.info.id), isFalse);
      expect(siteRegistry.revision, greaterThan(revisionBeforeRemove));
      expect(siteRegistry.contains(AsmrOneSiteApi.info.id), isTrue);
      expect(siteRegistry.contains(AsmrGaySiteApi.info.id), isTrue);
    },
  );

  test('invalid persisted Kikoeru servers do not register the site', () async {
    await CacheService.instance.saveSiteServers(const [
      ServerInfo(
        id: 'invalid',
        baseUrl: 'ftp://invalid.example.com',
        label: 'Invalid',
      ),
    ], siteId: KikoeruSiteApi.info.id);

    await setupSiteApi();

    expect(siteRegistry.contains(KikoeruSiteApi.info.id), isFalse);
    expect(siteRegistry.contains(AsmrOneSiteApi.info.id), isTrue);
  });

  testWidgets(
    'site selection refreshes when Kikoeru is dynamically registered',
    (tester) async {
      await tester.runAsync(setupSiteApi);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SiteSelectionModal())),
        ),
      );
      await tester.pump();
      expect(find.text('Kikoeru 自建站'), findsNothing);

      const server = ServerInfo(
        id: 'widget-nas',
        baseUrl: 'https://widget.example.com',
        label: 'Widget NAS',
        useProxy: false,
        isDefault: true,
      );
      await tester.runAsync(
        () => updateSiteServers(KikoeruSiteApi.info.id, const [server]),
      );
      await tester.pump();
      expect(find.text('Kikoeru 自建站'), findsOneWidget);

      await tester.runAsync(
        () => updateSiteServers(KikoeruSiteApi.info.id, const []),
      );
      await tester.pump();
      expect(find.text('Kikoeru 自建站'), findsNothing);
    },
  );
}
