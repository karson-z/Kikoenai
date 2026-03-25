import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';

class ProxyService {
  ProxyService._();

  static Future<void> init() async {
    if (kIsWeb) return;

    String? proxyString;

    try {
      if (Platform.isWindows || Platform.isMacOS) {
        proxyString = await _getDesktopProxy();
      } else if (Platform.isAndroid || Platform.isIOS) {
        try {
          final settings = await NativeProxyReader.proxySetting;
          if (settings.enabled && settings.host != null) {
            proxyString = "${settings.host}:${settings.port}";

            NativeProxyReader.setProxyChangedCallback((newSettings) async {
              if (newSettings.enabled && newSettings.host != null) {
                _applyProxy("${newSettings.host}:${newSettings.port}");
              } else {
                _applyProxy(null);
              }
              return null;
            });
          }
        } catch (e) {
          KikoenaiLogger().e('[Proxy] 移动端插件初始化错误: $e');
        }
      }
    } catch (e) {
      KikoenaiLogger().e('[Proxy] 获取系统代理失败: $e');
    }

    _applyProxy(proxyString);
  }

  static void _applyProxy(String? proxyStr) {
    HttpOverrides.global = _GlobalHttpOverrides(proxyStr);
    if (proxyStr != null && proxyStr.isNotEmpty) {
      KikoenaiLogger().i('[Proxy] 全局代理已开启: $proxyStr, SSL证书校验已禁用');
    } else {
      KikoenaiLogger().i('[Proxy] 未检测到代理，使用直连, SSL证书校验已禁用');
    }
  }

  static Future<String?> _getDesktopProxy() async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsProxy();
      } else if (Platform.isMacOS) {
        return await _getMacOSProxy();
      }
    } catch (e) {
      KikoenaiLogger().e('桌面端获取代理失败: $e');
    }
    return null;
  }

  static Future<String?> _getWindowsProxy() async {
    final result = await Process.run('reg', [
      'query',
      r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v',
      'ProxyServer'
    ]);

    final enableResult = await Process.run('reg', [
      'query',
      r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v',
      'ProxyEnable'
    ]);

    if (!enableResult.stdout.toString().contains('0x1')) return null;

    final output = result.stdout.toString();
    final RegExp regExp = RegExp(r'ProxyServer\s+REG_SZ\s+([^\r\n]+)');
    final match = regExp.firstMatch(output);

    if (match != null) {
      String rawProxy = match.group(1)?.trim() ?? '';

      if (rawProxy.contains('=')) {
        final parts = rawProxy.split(';');
        for (var part in parts) {
          if (part.startsWith('http=') || part.startsWith('https=')) {
            return part.split('=')[1];
          }
        }
      } else {
        return rawProxy;
      }
    }
    return null;
  }

  static Future<String?> _getMacOSProxy() async {
    final result = await Process.run('scutil', ['--proxy']);
    final output = result.stdout.toString();
    final Map<String, String> proxyConfig = {};

    final lines = output.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          proxyConfig[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }
    }

    if (proxyConfig['HTTPEnable'] == '1') {
      final host = proxyConfig['HTTPProxy'];
      final port = proxyConfig['HTTPPort'];
      if (host != null && port != null) {
        return "$host:$port";
      }
    }
    return null;
  }
}

class _GlobalHttpOverrides extends HttpOverrides {
  final String? proxyString;

  _GlobalHttpOverrides(this.proxyString);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    client.findProxy = (uri) {
      if (proxyString != null && proxyString!.isNotEmpty) {
        return "PROXY $proxyString; DIRECT";
      }
      return "DIRECT";
    };

    client.badCertificateCallback = (cert, host, port) => true;

    return client;
  }
}