import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/proxy/auto_proxy_service.dart';
import 'package:kikoenai/core/service/proxy/system_proxy_config.dart';
import 'package:kikoenai/core/utils/scraper/scraper_http_client.dart';
import 'package:kikoenai_sites/network/http_client.dart';
import 'package:kikoenai_sites/network/request_config.dart';

Future<String> read(HttpClient client, String url) async {
  final response = await (await client.getUrl(Uri.parse(url))).close();
  return response.transform(utf8.decoder).join();
}

Future<HttpServer> fakeProxy(String body, List<String> requests) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    requests.add(request.uri.toString());
    request.response.persistentConnection = false;
    request.response.write(body);
    await request.response.close();
  });
  return server;
}

void main() {
  test(
    'existing client follows A -> B -> DIRECT without being recreated',
    () async {
      final hits = <String>[];
      final a = await fakeProxy('A', hits);
      final b = await fakeProxy('B', hits);
      final direct = await fakeProxy('DIRECT', <String>[]);
      var config = SystemProxyConfig.single(ProxyEndpoint('127.0.0.1', a.port));
      final client = SystemProxyHttpOverrides(
        () => config,
      ).createHttpClient(null);
      addTearDown(() async {
        client.close(force: true);
        await Future.wait([
          a.close(force: true),
          b.close(force: true),
          direct.close(force: true),
        ]);
      });
      expect(await read(client, 'http://proxy-target.invalid/probe'), 'A');
      config = SystemProxyConfig.single(ProxyEndpoint('127.0.0.1', b.port));
      expect(await read(client, 'http://proxy-target.invalid/probe'), 'B');
      config = SystemProxyConfig.direct;
      expect(
        await read(client, 'http://127.0.0.1:${direct.port}/probe'),
        'DIRECT',
      );
      expect(hits, hasLength(2));
    },
  );

  test(
    'HTTPS reaches TLS origin through a CONNECT tunnel with certificate verification',
    () async {
      final context = SecurityContext()
        ..useCertificateChain('test/fixtures/proxy/cert.pem')
        ..usePrivateKey('test/fixtures/proxy/key.pem');
      final origin = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      origin.listen((request) async {
        request.response.write('TLS origin');
        await request.response.close();
      });
      final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      final connectLines = <String>[];
      proxy.listen((socket) {
        sockets.add(socket);
        final header = <int>[];
        Socket? upstream;
        socket.listen((data) async {
          if (upstream != null) {
            upstream!.add(data);
            return;
          }
          header.addAll(data);
          final text = latin1.decode(header);
          if (!text.contains('\r\n\r\n')) return;
          connectLines.add(text.split('\r\n').first);
          upstream = await Socket.connect('127.0.0.1', origin.port);
          sockets.add(upstream!);
          socket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
          upstream!.listen(socket.add, onDone: socket.destroy);
        }, onDone: () => upstream?.destroy());
      });
      final trustedContext = SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificates('test/fixtures/proxy/cert.pem');
      final client = SystemProxyHttpOverrides(
        () => SystemProxyConfig.single(ProxyEndpoint('127.0.0.1', proxy.port)),
      ).createHttpClient(trustedContext);
      addTearDown(() async {
        client.close(force: true);
        for (final socket in sockets) {
          socket.destroy();
        }
        await proxy.close();
        await origin.close(force: true);
      });
      expect(
        await read(client, 'https://localhost:${origin.port}/secure'),
        'TLS origin',
      );
      expect(connectLines, ['CONNECT localhost:${origin.port} HTTP/1.1']);
    },
  );

  test(
    'scraper inherits global proxy, explicit override works, site opt-out stays direct',
    () async {
      final hits = <String>[];
      final global = await fakeProxy('global', hits);
      final explicit = await fakeProxy('explicit', hits);
      final origin = await fakeProxy('direct', <String>[]);
      addTearDown(() async {
        ScraperHttpClient.setProxy(null, null);
        await Future.wait([
          global.close(force: true),
          explicit.close(force: true),
          origin.close(force: true),
        ]);
      });
      await HttpOverrides.runWithHttpOverrides(
        () async {
          ScraperHttpClient.setProxy(null, null);
          expect(
            (await ScraperHttpClient.retryGet(
              'http://scraper.invalid/probe',
              customRetryConfig: {'limit': 0},
            )).data,
            'global',
          );
          ScraperHttpClient.setProxy('127.0.0.1', explicit.port.toString());
          expect(
            (await ScraperHttpClient.retryGet(
              'http://scraper.invalid/probe',
              customRetryConfig: {'limit': 0},
            )).data,
            'explicit',
          );
          ScraperHttpClient.setProxy(null, null);
          expect(
            (await ScraperHttpClient.retryGet(
              'http://scraper.invalid/probe',
              customRetryConfig: {'limit': 0},
            )).data,
            'global',
          );
          final site = SitesHttpClient(
            config: RequestConfig(
              baseUrl: 'http://127.0.0.1:${origin.port}',
              useProxy: false,
            ),
          );
          try {
            expect((await site.dio.get('/probe')).data, 'direct');
          } finally {
            site.dio.close(force: true);
          }
        },
        SystemProxyHttpOverrides(
          () =>
              SystemProxyConfig.single(ProxyEndpoint('127.0.0.1', global.port)),
        ),
      );
      expect(hits, hasLength(3));
    },
  );
}
