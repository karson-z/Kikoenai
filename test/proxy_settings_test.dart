import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/proxy/proxy_settings.dart';
import 'package:kikoenai/core/storage/hive_key.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(
      'kikoenai_proxy_settings_',
    );
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>('proxy_settings');
  });

  tearDown(() => box.clear());
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('settings survive reopening without changing unrelated data', () async {
    await box.put('existing_setting', 'preserved');
    const settings = ProxySettings(
      enabled: true,
      configured: true,
      url: 'http://127.0.0.1:7890',
      testUrl: 'https://example.com/probe',
    );
    await settings.save(box);
    await box.close();
    box = await Hive.openBox<dynamic>('proxy_settings');
    final restored = ProxySettings.fromStorage(box);
    expect(restored.isActive, isTrue);
    expect(restored.url, settings.url);
    expect(restored.testUrl, settings.testUrl);
    expect(box.get('existing_setting'), 'preserved');

    await restored.copyWith(enabled: false).save(box);
    final disabled = ProxySettings.fromStorage(box);
    expect(disabled.isActive, isFalse);
    expect(disabled.configured, isTrue);
    expect(disabled.url, settings.url);
  });

  test('untested or invalid saved endpoints cannot be enabled', () async {
    for (final value in [
      {'enabled': true, 'configured': false, 'url': 'localhost:7890'},
      {'enabled': true, 'configured': true, 'url': 'socks5://localhost:1080'},
    ]) {
      await box.put(StorageKeys.networkProxy, value);
      expect(ProxySettings.fromStorage(box).isActive, isFalse);
    }
    expect(
      () => const ProxySettings(enabled: true, url: 'localhost:7890').save(box),
      throwsStateError,
    );
  });

  test(
    'connection test sends the target request through the candidate proxy',
    () async {
      final requests = <String>[];
      final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => proxy.close(force: true));
      proxy.listen((request) async {
        requests.add(request.uri.toString());
        request.response.write('OK');
        await request.response.close();
      });
      await ProxySettings(
        url: '127.0.0.1:${proxy.port}',
        testUrl: 'http://unresolvable-proxy-target.invalid/probe',
      ).testConnection();
      expect(requests, ['http://unresolvable-proxy-target.invalid/probe']);
    },
  );

  test(
    'unreachable proxy cannot pass by falling back to the reachable origin',
    () async {
      var originHits = 0;
      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      origin.listen((request) async {
        originHits++;
        await request.response.close();
      });
      addTearDown(() => origin.close(force: true));
      final closedProxy = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = closedProxy.port;
      await closedProxy.close();
      await expectLater(
        ProxySettings(
          url: '127.0.0.1:$port',
          testUrl: 'http://127.0.0.1:${origin.port}/probe',
        ).testConnection(timeout: const Duration(seconds: 2)),
        throwsA(isA<SocketException>()),
      );
      expect(originHits, 0);
    },
  );

  test('non-success test responses do not validate a proxy', () async {
    final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => proxy.close(force: true));
    proxy.listen((request) async {
      request.response.statusCode = HttpStatus.proxyAuthenticationRequired;
      await request.response.close();
    });
    await expectLater(
      ProxySettings(
        url: '127.0.0.1:${proxy.port}',
        testUrl: 'http://example.invalid/probe',
      ).testConnection(),
      throwsA(isA<HttpException>()),
    );
  });
}
