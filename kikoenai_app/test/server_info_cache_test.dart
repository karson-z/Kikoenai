import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'kikoenai_server_cache_test_',
    );
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(ServerInfoAdapter());
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings_test');
  });

  tearDown(() async {
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
}
