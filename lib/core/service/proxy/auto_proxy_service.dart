import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';

import 'system_proxy_config.dart';

class ProxyService {
  ProxyService._();

  static SystemProxyConfig get current => _current;
  static SystemProxyConfig _current = SystemProxyConfig.direct;
  static final _changes = StreamController<SystemProxyConfig>.broadcast(
    sync: true,
  );
  static Stream<SystemProxyConfig> get changes => _changes.stream;
  static Future<void>? _initialization;
  static Future<void>? _refreshing;
  static Timer? _poll;
  static AppLifecycleListener? _lifecycle;
  static int _revision = 0;
  static Future<SystemProxyConfig> Function() _reader = _readSystemProxy;

  static Future<void> init({
    @visibleForTesting Future<SystemProxyConfig> Function()? readSettings,
  }) {
    if (kIsWeb) return Future.value();
    return _initialization ??= _initialize(readSettings);
  }

  static Future<void> _initialize(
    Future<SystemProxyConfig> Function()? reader,
  ) async {
    _reader = reader ?? _readSystemProxy;
    // Existing clients consult the current configuration for new connections.
    HttpOverrides.global = SystemProxyHttpOverrides(() => _current);
    if (Platform.isAndroid || Platform.isIOS) {
      // Register even when the app starts without a proxy.
      NativeProxyReader.setProxyChangedCallback((settings) async {
        _apply(_fromMobile(settings));
        return null;
      });
    }
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
    await refresh();
    if (Platform.isWindows || Platform.isMacOS) {
      _poll = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(refresh()),
      );
    }
  }

  static Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() {
    _refreshing = null;
  });

  static Future<void> _refresh() async {
    final revision = _revision;
    try {
      final config = await _reader();
      // A native notification may have arrived while reading settings.
      if (revision == _revision) _apply(config);
    } catch (error) {
      // A read failure does not mean the proxy has been disabled.
      KikoenaiLogger().e('[Proxy] 读取系统代理失败，保留上次配置: $error');
    }
  }

  static void _apply(SystemProxyConfig config) {
    _revision++;
    if (config == _current) return;
    _current = config;
    _changes.add(config);
    KikoenaiLogger().i('[Proxy] 系统代理配置已更新');
  }

  static SystemProxyConfig _fromMobile(ProxySetting settings) {
    if (!settings.enabled || settings.host == null || settings.port == null) {
      return SystemProxyConfig.direct;
    }
    final host = settings.host!;
    return SystemProxyConfig.single(
      ProxyEndpoint.parse(
        '${host.contains(':') && !host.startsWith('[') ? '[$host]' : host}:${settings.port}',
      ),
    );
  }

  static Future<SystemProxyConfig> _readSystemProxy() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _fromMobile(await NativeProxyReader.proxySetting);
    }
    if (Platform.isWindows) {
      final result = await Process.run('reg', [
        'query',
        r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      ]).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) {
        throw StateError('reg query: ${result.exitCode}');
      }
      return SystemProxyConfig.fromWindowsRegistry(result.stdout.toString());
    }
    if (Platform.isMacOS) {
      final result = await Process.run('scutil', [
        '--proxy',
      ]).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) throw StateError('scutil: ${result.exitCode}');
      return SystemProxyConfig.fromScutil(result.stdout.toString());
    }
    return SystemProxyConfig.direct;
  }

  @visibleForTesting
  static void dispose() {
    _poll?.cancel();
    _poll = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _revision++;
    _initialization = null;
    _current = SystemProxyConfig.direct;
  }
}

class SystemProxyHttpOverrides extends HttpOverrides {
  SystemProxyHttpOverrides(this.readConfig);

  final SystemProxyConfig Function() readConfig;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => readConfig().findProxy(uri);
    return client;
  }
}
