import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/proxy/system_proxy_config.dart';

void main() {
  test(
    'Windows separates HTTP/HTTPS, bypasses local names, honors disable',
    () {
      const registry = '''
    ProxyEnable    REG_DWORD    0x1
    ProxyServer    REG_SZ    http=127.0.0.1:8080;https=[::1]:8443;socks=localhost:1080
    ProxyOverride    REG_SZ    <local>;*.internal;10.0.0.0/8;example.org:443
''';
      final config = SystemProxyConfig.fromWindowsRegistry(registry);
      expect(
        config.proxyFor(Uri.parse('http://example.com')),
        const ProxyEndpoint('127.0.0.1', 8080),
      );
      expect(
        config.proxyFor(Uri.parse('https://example.com'))?.authority,
        '[::1]:8443',
      );
      for (final url in [
        'http://nas',
        'https://a.internal',
        'http://10.2.3.4',
        'https://example.org',
      ]) {
        expect(config.findProxy(Uri.parse(url)), 'DIRECT');
      }
      expect(config.proxyFor(Uri.parse('http://110.2.3.4')), isNotNull);
      expect(
        SystemProxyConfig.fromWindowsRegistry(
          registry.replaceFirst('0x1', '0x0'),
        ),
        SystemProxyConfig.direct,
      );
    },
  );

  test('macOS ignores nested scoped settings and reads exception arrays', () {
    final config = SystemProxyConfig.fromScutil('''
<dictionary> {
  HTTPEnable : 1
  HTTPProxy : localhost
  HTTPPort : 8080
  HTTPSEnable : 1
  HTTPSProxy : ::1
  HTTPSPort : 8443
  ExceptionsList : <array> {
    0 : *.local
    1 : 192.168.0.0/16
  }
  ExcludeSimpleHostnames : 1
  __SCOPED__ : <dictionary> {
    en0 : <dictionary> {
      HTTPProxy : wrong-proxy
      HTTPPort : 99
    }
  }
}
''');
    expect(config.http, const ProxyEndpoint('localhost', 8080));
    expect(config.https, const ProxyEndpoint('::1', 8443));
    for (final url in ['http://nas', 'http://a.local', 'https://192.168.1.1']) {
      expect(config.findProxy(Uri.parse(url)), 'DIRECT');
    }
    expect(config.proxyFor(Uri.parse('https://192.169.1.1')), isNotNull);
  });

  test('proxy parsing rejects invalid endpoints and unsupported protocols', () {
    for (final value in [
      '',
      'localhost',
      'localhost:0',
      'localhost:65536',
      'socks5://localhost:1080',
      'http://user:pass@localhost:80',
      'localhost:80/path',
    ]) {
      expect(ProxyEndpoint.parse(value), isNull, reason: value);
    }
    expect(ProxyEndpoint.parse('[::1]:8080')?.url, 'http://[::1]:8080');
    final config = SystemProxyConfig.single(
      const ProxyEndpoint('localhost', 8080),
    );
    expect(config.findProxy(Uri.file('/tmp/audio.mp3')), 'DIRECT');
    expect(
      config,
      SystemProxyConfig.single(const ProxyEndpoint('localhost', 8080)),
    );
  });
}
