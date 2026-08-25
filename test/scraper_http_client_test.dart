import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/scraper/scraper_http_client.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    ScraperHttpClient.setProxy(null, null);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test(
    'cancelling a scraper token interrupts an active HTTP request',
    () async {
      final requestReceived = Completer<void>();
      server.listen((request) {
        if (!requestReceived.isCompleted) requestReceived.complete();
      });

      final cancellationToken = ScraperCancellationToken();
      final request = ScraperHttpClient.retryGet(
        'http://${server.address.host}:${server.port}/slow',
        customRetryConfig: const {'limit': 0},
        cancellationToken: cancellationToken,
      );

      await requestReceived.future.timeout(const Duration(seconds: 2));
      cancellationToken.cancel('test pause');

      await expectLater(
        request,
        throwsA(
          isA<ScraperCancelledException>().having(
            (error) => error.reason,
            'reason',
            'test pause',
          ),
        ),
      );
    },
  );
}
