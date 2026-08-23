import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/network/request_config.dart';

void main() {
  group('RequestConfig', () {
    test('defaultConfig 正确设置默认值', () {
      final config = RequestConfig.defaultConfig();
      expect(config.baseUrl, 'https://api.asmr-200.com/api');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.userAgent, 'kikoenai-sites/0.1.0');
      expect(config.accept, 'application/json');
      expect(config.useProxy, isTrue);
    });

    test('copyWith 正确覆盖指定字段', () {
      final config = RequestConfig.defaultConfig();
      final updated = config.copyWith(
        baseUrl: 'https://custom.example.com/api',
        userAgent: 'MyApp/1.0',
        useProxy: false,
      );
      expect(updated.baseUrl, 'https://custom.example.com/api');
      expect(updated.userAgent, 'MyApp/1.0');
      // 未修改字段保持不变
      expect(updated.accept, 'application/json');
      expect(updated.useProxy, isFalse);
    });

    test('defaultHeaders 包含 User-Agent / Referer / Accept', () {
      const config = RequestConfig(
        baseUrl: 'https://test.com',
        userAgent: 'UA',
        referer: 'https://ref.com',
        accept: 'text/html',
      );
      final headers = config.defaultHeaders;
      expect(headers['User-Agent'], 'UA');
      expect(headers['Referer'], 'https://ref.com');
      expect(headers['Accept'], 'text/html');
    });

    test('extraHeaders 被合并到 defaultHeaders', () {
      const config = RequestConfig(
        baseUrl: 'https://test.com',
        extraHeaders: {'X-Custom': 'yes'},
      );
      expect(config.defaultHeaders['X-Custom'], 'yes');
    });
  });
}
