import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/proxy/auto_proxy_service.dart';
import 'package:kikoenai/core/service/proxy/proxy_settings.dart';
import 'package:kikoenai/core/service/proxy/system_proxy_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an existing HTTP client follows system -> manual A -> manual B -> system',
    () async {
      final previousOverrides = HttpOverrides.current;
      final servers = <HttpServer>[];
      Future<HttpServer> proxy(String label) async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        servers.add(server);
        server.listen((request) async {
          request.response.write(label);
          await request.response.close();
        });
        return server;
      }

      final system = await proxy('system');
      final manualA = await proxy('manual A');
      final manualB = await proxy('manual B');
      HttpClient? client;
      addTearDown(() async {
        client?.close(force: true);
        ProxyService.dispose();
        HttpOverrides.global = previousOverrides;
        await Future.wait(servers.map((server) => server.close(force: true)));
      });
      await ProxyService.init(
        readSettings: () async =>
            SystemProxyConfig.single(ProxyEndpoint('127.0.0.1', system.port)),
      );
      client = HttpClient();
      Future<String> fetch() async {
        final response = await (await client!.getUrl(
          Uri.parse('http://proxy-target.invalid/probe'),
        )).close();
        return response.transform(utf8.decoder).join();
      }

      ProxySettings manual(int port) => ProxySettings(
        enabled: true,
        configured: true,
        url: '127.0.0.1:$port',
      );
      expect(await fetch(), 'system');
      ProxyService.setManualSettings(manual(manualA.port));
      expect(await fetch(), 'manual A');
      ProxyService.setManualSettings(manual(manualB.port));
      expect(await fetch(), 'manual B');
      ProxyService.setManualSettings(
        manual(manualB.port).copyWith(enabled: false),
      );
      expect(await fetch(), 'system');
    },
  );

  test(
    'manual proxy wins while system changes are retained for disabling it',
    () async {
      final previousOverrides = HttpOverrides.current;
      var system = SystemProxyConfig.single(
        const ProxyEndpoint('system-a', 8080),
      );
      final changes = <SystemProxyConfig>[];
      final subscription = ProxyService.changes.listen(changes.add);
      addTearDown(() async {
        ProxyService.dispose();
        HttpOverrides.global = previousOverrides;
        await subscription.cancel();
      });
      const manual = ProxySettings(
        enabled: true,
        configured: true,
        url: 'http://manual:7890',
      );
      await ProxyService.init(
        manualSettings: manual,
        readSettings: () async => system,
      );
      final uri = Uri.parse('https://example.com');
      expect(ProxyService.current.findProxy(uri), 'PROXY manual:7890');
      expect(changes, hasLength(1));

      system = SystemProxyConfig.single(const ProxyEndpoint('system-b', 9090));
      await ProxyService.refresh();
      expect(ProxyService.current.findProxy(uri), 'PROXY manual:7890');
      expect(changes, hasLength(1));

      ProxyService.setManualSettings(manual.copyWith(enabled: false));
      expect(ProxyService.current, system);
      expect(changes, hasLength(2));
      expect(ProxyService.manualSettings.url, manual.url);

      ProxyService.setManualSettings(manual);
      expect(ProxyService.current.findProxy(uri), 'PROXY manual:7890');
      expect(
        () => ProxyService.setManualSettings(
          const ProxySettings(enabled: true, url: 'unvalidated:7890'),
        ),
        throwsStateError,
      );
      expect(ProxyService.current.findProxy(uri), 'PROXY manual:7890');
    },
  );

  test(
    'initialization is idempotent, failed reads retain state, and refreshes coalesce',
    () async {
      final previousOverrides = HttpOverrides.current;
      var config = SystemProxyConfig.direct;
      var fail = false;
      var reads = 0;
      Completer<void>? gate;
      final changes = <SystemProxyConfig>[];
      final subscription = ProxyService.changes.listen(changes.add);
      addTearDown(() async {
        ProxyService.dispose();
        HttpOverrides.global = previousOverrides;
        await subscription.cancel();
      });
      Future<SystemProxyConfig> readSettings() async {
        reads++;
        if (gate != null) await gate.future;
        if (fail) throw StateError('temporary settings failure');
        return config;
      }

      await ProxyService.init(readSettings: readSettings);
      await ProxyService.init(readSettings: readSettings);
      expect(reads, 1);
      expect(changes, isEmpty);

      config = SystemProxyConfig.single(const ProxyEndpoint('localhost', 8080));
      await ProxyService.refresh();
      expect(ProxyService.current, config);
      expect(changes, [config]);

      fail = true;
      await ProxyService.refresh();
      expect(ProxyService.current, config);
      expect(changes, hasLength(1));
      fail = false;

      config = SystemProxyConfig.direct;
      gate = Completer<void>();
      final a = ProxyService.refresh();
      final b = ProxyService.refresh();
      expect(identical(a, b), isTrue);
      gate.complete();
      await Future.wait([a, b]);
      expect(reads, 4);
      expect(ProxyService.current, SystemProxyConfig.direct);
      expect(changes, hasLength(2));
    },
  );
}
