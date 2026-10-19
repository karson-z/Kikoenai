import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/download/download_proxy_sync.dart';
import 'package:kikoenai/core/service/proxy/system_proxy_config.dart';

void main() {
  test(
    'updates serialize; disabling clears stale proxy before next task',
    () async {
      var config = SystemProxyConfig.single(const ProxyEndpoint('a', 8080));
      final writes = <Object>[];
      final gate = Completer<void>();
      final started = Completer<void>();
      final sync = DownloadProxySync(
        readConfig: () => config,
        configure: (value) async {
          writes.add(value);
          if (writes.length == 1) {
            started.complete();
            await gate.future;
          }
        },
      );
      final first = sync.sync();
      await started.future;
      config = SystemProxyConfig.single(const ProxyEndpoint('b', 9090));
      final second = sync.sync();
      expect(writes, [('a', 8080)]);
      gate.complete();
      await Future.wait([first, second]);
      config = SystemProxyConfig.direct;
      await sync.sync();
      await sync.sync();
      expect(writes, [('a', 8080), ('b', 9090), false]);
    },
  );

  test('a failed native write is retried before the next task', () async {
    var attempts = 0;
    final sync = DownloadProxySync(
      readConfig: () =>
          SystemProxyConfig.single(const ProxyEndpoint('a', 8080)),
      configure: (_) async {
        if (++attempts == 1) throw StateError('write failed');
      },
    );
    await expectLater(sync.sync(), throwsStateError);
    await sync.sync();
    expect(attempts, 2);
  });

  test(
    'iOS clears persisted override once and keeps URLSession system routing',
    () async {
      final writes = <Object>[];
      final sync = DownloadProxySync(
        useSystemProxy: true,
        readConfig: () =>
            SystemProxyConfig.single(const ProxyEndpoint('a', 8080)),
        configure: (value) async => writes.add(value),
      );
      await sync.sync();
      await sync.sync();
      expect(writes, [false]);
    },
  );
}
