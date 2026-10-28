import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kikoenai/core/service/player/player_service.dart';
import 'package:kikoenai/core/service/proxy/auto_proxy_service.dart';
import 'package:kikoenai/core/service/proxy/proxy_settings.dart';
import 'package:kikoenai/core/service/proxy/system_proxy_config.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late PlayerService service;
  late NativePlayer native;
  late _RecordingProxy proxyA;
  late _RecordingProxy proxyB;
  late _RecordingProxy systemProxy;
  late HttpServer origin;
  late HttpServer secureOrigin;
  late Directory certificates;
  final originRequests = <String>[];
  final secureRequests = <String>[];
  final errors = <String>[];
  late StreamSubscription<String> errorSubscription;
  var systemConfig = SystemProxyConfig.direct;

  setUpAll(() async {
    const certificateBase64 = String.fromEnvironment(
      'PLAYER_PROXY_TEST_CERT_B64',
    );
    const privateKeyBase64 = String.fromEnvironment(
      'PLAYER_PROXY_TEST_KEY_B64',
    );
    expect(
      certificateBase64,
      isNotEmpty,
      reason: 'Run tool/test_player_proxy.sh',
    );
    expect(
      privateKeyBase64,
      isNotEmpty,
      reason: 'Run tool/test_player_proxy.sh',
    );
    final certificate = utf8.decode(base64.decode(certificateBase64));
    final privateKey = utf8.decode(base64.decode(privateKeyBase64));

    proxyA = await _RecordingProxy.start();
    proxyB = await _RecordingProxy.start();
    systemProxy = await _RecordingProxy.start();
    origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin.listen((request) => _serveWav(request, originRequests));
    final context = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(certificate))
      ..usePrivateKeyBytes(utf8.encode(privateKey));
    secureOrigin = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    secureOrigin.listen((request) => _serveWav(request, secureRequests));
    certificates = await Directory.systemTemp.createTemp('player_proxy_tls_');
    final caFile = await File(
      '${certificates.path}/ca.pem',
    ).writeAsString(certificate);

    MediaKit.ensureInitialized();
    // This uses the real native decoder with null audio/video outputs.
    NativePlayer.test = true;
    await ProxyService.init(readSettings: () async => systemConfig);
    service = PlayerService.instance;
    native = service.player.platform as NativePlayer;
    await native.setProperty('tls-verify', 'yes');
    await native.setProperty('tls-ca-file', caFile.path);
    await native.setProperty('network-timeout', '3');
    errorSubscription = service.player.stream.error.listen(errors.add);
    // ignore: avoid_print
    print('Native player: ${await native.getProperty('mpv-version')}');
  });

  tearDown(() async {
    await service.player.stop();
    errors.clear();
  });

  tearDownAll(() async {
    await errorSubscription.cancel();
    await service.dispose();
    ProxyService.dispose();
    await Future.wait([
      proxyA.close(),
      proxyB.close(),
      systemProxy.close(),
      origin.close(force: true),
      secureOrigin.close(force: true),
    ]);
    await certificates.delete(recursive: true);
  });

  ProxySettings manual(_RecordingProxy proxy) =>
      ProxySettings(enabled: true, configured: true, url: proxy.endpoint.url);

  Future<void> play(String url) async {
    await service.player.stop();
    final progressed = service.player.stream.position.firstWhere(
      (position) => position >= const Duration(milliseconds: 100),
    );
    await service.player.open(Media(url));
    await progressed.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Native playback did not advance: $errors');
      },
    );
    expect(service.player.state.duration, greaterThan(Duration.zero));
    expect(errors, isEmpty);
  }

  testWidgets(
    'HTTP playback follows manual A, manual B, then the system proxy',
    (_) async {
      for (final (proxy, label) in [
        (proxyA, 'manual-a'),
        (proxyB, 'manual-b'),
      ]) {
        ProxyService.setManualSettings(manual(proxy));
        final url = 'http://player-proxy.invalid/$label.wav';
        await play(url);
        expect(proxy.receivedGet(url), isTrue, reason: '${proxy.requests}');
        expect(await native.getProperty('http-proxy'), proxy.endpoint.url);
        // ignore: avoid_print
        print('PASS $label: proxy received GET and native playback advanced');
      }

      systemConfig = SystemProxyConfig.single(systemProxy.endpoint);
      await ProxyService.refresh();
      ProxyService.setManualSettings(manual(proxyB).copyWith(enabled: false));
      const url = 'http://player-proxy.invalid/system.wav';
      await play(url);
      expect(
        systemProxy.receivedGet(url),
        isTrue,
        reason: '${systemProxy.requests}',
      );
      expect(await native.getProperty('http-proxy'), systemProxy.endpoint.url);
    },
  );

  testWidgets(
    'system bypass and disabling all proxies reach the origin directly',
    (_) async {
      ProxyService.setManualSettings(const ProxySettings());
      systemConfig = SystemProxyConfig(
        http: systemProxy.endpoint,
        https: systemProxy.endpoint,
        bypass: const ['127.0.0.1'],
      );
      await ProxyService.refresh();
      final counts = [
        proxyA.requests.length,
        proxyB.requests.length,
        systemProxy.requests.length,
      ];
      await play('http://127.0.0.1:${origin.port}/bypass.wav');
      expect(originRequests, contains('/bypass.wav'));
      expect(await native.getProperty('http-proxy'), isEmpty);

      systemConfig = SystemProxyConfig.direct;
      await ProxyService.refresh();
      await play('http://127.0.0.1:${origin.port}/direct.wav');
      expect(originRequests, contains('/direct.wav'));
      expect([
        proxyA.requests.length,
        proxyB.requests.length,
        systemProxy.requests.length,
      ], counts);
    },
  );

  testWidgets('HTTPS playback uses CONNECT and verifies the origin certificate', (
    _,
  ) async {
    ProxyService.setManualSettings(manual(proxyA));
    await play('https://localhost:${secureOrigin.port}/secure.wav');
    expect(proxyA.requests, contains('CONNECT localhost:${secureOrigin.port}'));
    expect(secureRequests, contains('/secure.wav'));
    expect(await native.getProperty('tls-verify'), 'yes');
    // ignore: avoid_print
    print(
      'PASS HTTPS: CONNECT received, certificate verified, native playback advanced',
    );
  });

  testWidgets(
    'an unavailable manual proxy fails instead of playing the reachable origin directly',
    (_) async {
      final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = closed.port;
      await closed.close();
      ProxyService.setManualSettings(
        ProxySettings(enabled: true, configured: true, url: '127.0.0.1:$port'),
      );
      final failure = service.player.stream.error.first;
      await service.player.open(
        Media('http://127.0.0.1:${origin.port}/must-not-be-direct.wav'),
      );
      expect(await failure.timeout(const Duration(seconds: 15)), isNotEmpty);
      expect(originRequests, isNot(contains('/must-not-be-direct.wav')));
      expect(service.player.state.duration, Duration.zero);
    },
  );
}

final _wav = _createWav();

Uint8List _createWav() {
  const sampleRate = 16000;
  const samples = sampleRate * 2;
  final data = ByteData(44 + samples * 2);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  data.setUint32(4, data.lengthInBytes - 8, Endian.little);
  text(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  text(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  return data.buffer.asUint8List();
}

Future<void> _serveWav(HttpRequest request, List<String> requests) async {
  requests.add(request.uri.toString());
  request.response
    ..headers.contentType = ContentType('audio', 'wav')
    ..contentLength = _wav.length
    ..add(_wav);
  await request.response.close();
}

/// A loopback-only fixture: HTTP serves a WAV for an unresolvable target;
/// CONNECT is restricted to the local TLS origin.
class _RecordingProxy {
  _RecordingProxy(this.server);
  final ServerSocket server;
  final requests = <String>[];
  final sockets = <Socket>[];

  ProxyEndpoint get endpoint => ProxyEndpoint('127.0.0.1', server.port);

  bool receivedGet(String url) {
    final expected = Uri.parse(url);
    return requests.any((line) {
      if (!line.startsWith('GET ')) return false;
      final actual = Uri.parse(line.substring(4));
      return actual.scheme == expected.scheme &&
          actual.host == expected.host &&
          actual.port == expected.port &&
          actual.path == expected.path &&
          actual.query == expected.query;
    });
  }

  static Future<_RecordingProxy> start() async {
    final proxy = _RecordingProxy(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    proxy.server.listen(proxy._accept);
    return proxy;
  }

  void _accept(Socket downstream) {
    sockets.add(downstream);
    final header = <int>[];
    late StreamSubscription<Uint8List> subscription;
    subscription = downstream.listen((data) async {
      header.addAll(data);
      final boundary = latin1.decode(header).indexOf('\r\n\r\n');
      if (boundary < 0) return;
      subscription.pause();
      try {
        final line = latin1.decode(header).split('\r\n').first.split(' ');
        requests.add('${line[0]} ${line[1]}');
        if (line[0] == 'CONNECT') {
          final target = Uri.parse('http://${line[1]}');
          if (target.host != 'localhost') {
            throw StateError('Nonlocal CONNECT target');
          }
          final upstream = await Socket.connect(
            InternetAddress.loopbackIPv4,
            target.port,
          );
          sockets.add(upstream);
          downstream.write('HTTP/1.1 200 Connection Established\r\n\r\n');
          final remainder = header.sublist(boundary + 4);
          if (remainder.isNotEmpty) upstream.add(remainder);
          upstream.listen(
            downstream.add,
            onError: (_) => downstream.destroy(),
            onDone: downstream.destroy,
          );
          subscription.onData(upstream.add);
          subscription.onDone(upstream.destroy);
          subscription.resume();
        } else {
          downstream.write(
            'HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nContent-Length: ${_wav.length}\r\nConnection: close\r\n\r\n',
          );
          downstream.add(_wav);
          await downstream.close();
          await subscription.cancel();
        }
      } catch (_) {
        downstream.destroy();
        await subscription.cancel();
      }
    }, onError: (_) => downstream.destroy());
  }

  Future<void> close() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    await server.close();
  }
}
