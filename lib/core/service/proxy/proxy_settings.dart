import 'dart:io';

import 'package:hive_ce/hive.dart';

import '../../storage/hive_key.dart';
import 'system_proxy_config.dart';

/// The manual proxy takes precedence over the existing system proxy policy.
class ProxySettings {
  const ProxySettings({
    this.enabled = false,
    this.configured = false,
    this.url = '',
    this.testUrl = defaultTestUrl,
  });

  static const defaultTestUrl = 'https://www.google.com';

  final bool enabled;
  final bool configured;
  final String url;
  final String testUrl;

  ProxyEndpoint? get endpoint => ProxyEndpoint.parse(url);
  bool get isActive => enabled && configured && endpoint != null;

  factory ProxySettings.fromStorage(Box<dynamic> box) {
    final value = box.get(StorageKeys.networkProxy);
    if (value is! Map) return const ProxySettings();
    final settings = ProxySettings(
      enabled: value['enabled'] == true,
      configured: value['configured'] == true,
      url: value['url'] is String ? value['url'] as String : '',
      testUrl: value['testUrl'] is String
          ? value['testUrl'] as String
          : defaultTestUrl,
    );
    return settings.enabled && !settings.isActive
        ? settings.copyWith(enabled: false)
        : settings;
  }

  Future<void> save(Box<dynamic> box) {
    if (enabled && !isActive) {
      throw StateError('请先保存并测试代理配置');
    }
    // One value keeps the address and its test/enable state consistent.
    return box.put(StorageKeys.networkProxy, {
      'enabled': enabled,
      'configured': configured,
      'url': url,
      'testUrl': testUrl,
    });
  }

  ProxySettings copyWith({bool? enabled, bool? configured}) => ProxySettings(
    enabled: enabled ?? this.enabled,
    configured: configured ?? this.configured,
    url: url,
    testUrl: testUrl,
  );

  /// Test this endpoint explicitly, without falling back to a direct request
  /// or the system proxy. Keep normal HTTPS certificate verification.
  Future<void> testConnection({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final proxy = endpoint;
    final target = Uri.tryParse(testUrl);
    if (proxy == null ||
        target == null ||
        !['http', 'https'].contains(target.scheme) ||
        target.host.isEmpty ||
        target.userInfo.isNotEmpty) {
      throw const FormatException('请输入有效的代理地址和测试地址');
    }
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..findProxy = (_) => 'PROXY ${proxy.authority}';
    try {
      await (() async {
        final response = await (await client.getUrl(target)).close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException('测试返回 HTTP ${response.statusCode}');
        }
        await response.drain<void>();
      })().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}
