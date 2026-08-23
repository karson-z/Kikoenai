import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  test('resolvedBaseUrl applies an explicit port', () {
    const server = ServerInfo(
      id: 'custom',
      baseUrl: 'https://example.test/api',
      label: 'Custom',
      port: 8443,
      useProxy: false,
    );

    expect(server.resolvedBaseUrl, 'https://example.test:8443/api');
    expect(server.useProxy, isFalse);
  });

  test('Hive adapter persists port and proxy settings', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kikoenai_server_info_test_',
    );
    Hive.init(directory.path);
    Hive.registerAdapter(ServerInfoAdapter());
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    var box = await Hive.openBox<ServerInfo>('servers');
    const expected = ServerInfo(
      id: 'lan',
      baseUrl: 'http://192.168.1.8/api',
      label: 'LAN',
      port: 8080,
      useProxy: false,
      isDefault: true,
    );
    await box.put('lan', expected);
    await box.close();

    box = await Hive.openBox<ServerInfo>('servers');
    final restored = box.get('lan');
    expect(restored, expected);
    expect(restored?.resolvedBaseUrl, 'http://192.168.1.8:8080/api');
    expect(restored?.useProxy, isFalse);
  });
}
