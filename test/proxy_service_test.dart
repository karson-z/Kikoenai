import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/proxy/auto_proxy_service.dart';
import 'package:kikoenai/core/service/proxy/system_proxy_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
