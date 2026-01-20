import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';

class ProxyService {
  ProxyService._();

  /// 初始化全局代理
  static Future<void> init() async {
    // Web 端直接跳过
    if (kIsWeb) return;

    try {
      String? proxyString;

      if (Platform.isWindows || Platform.isMacOS) {
        // === 桌面端策略 (原生命令) ===
        proxyString = await _getDesktopProxy();
      } else if (Platform.isAndroid || Platform.isIOS) {
        // === 移动端策略 (插件) ===
        // 注意：移动端插件需要 try-catch 保护，防止未初始化时的报错
        try {
          final settings = await NativeProxyReader.proxySetting;
          if (settings.enabled && settings.host != null) {
            proxyString = "${settings.host}:${settings.port}";

            // 移动端支持动态监听
            NativeProxyReader.setProxyChangedCallback((newSettings) async {
              if (newSettings.enabled && newSettings.host != null) {
                _applyProxy("${newSettings.host}:${newSettings.port}");
              } else {
                HttpOverrides.global = null;
              }
              return null;
            });
          }
        } catch (e) {
          // 忽略移动端插件初始化错误
        }
      }

      // 应用代理
      if (proxyString != null) {
        _applyProxy(proxyString);
      }
    } catch (e) {
      KikoenaiLogger().e('️ [Proxy] 初始化失败: $e');
    }
  }

  /// 统一应用代理配置
  static void _applyProxy(String proxyStr) {
    HttpOverrides.global = _GlobalHttpOverrides(proxyStr);
    KikoenaiLogger().i(' [Proxy] 全局代理已开启: $proxyStr');
  }

  // ================= 桌面端核心逻辑 =================

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

  /// Windows: 读取注册表
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

    // 检查是否开启 (0x1)
    if (!enableResult.stdout.toString().contains('0x1')) return null;

    // 解析 ProxyServer (格式通常为 127.0.0.1:7890)
    final output = result.stdout.toString();
    final RegExp regExp = RegExp(r'ProxyServer\s+REG_SZ\s+(.*)');
    final match = regExp.firstMatch(output);

    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  /// macOS: 使用 scutil 命令
  static Future<String?> _getMacOSProxy() async {
    final result = await Process.run('scutil', ['--proxy']);
    final output = result.stdout.toString();
    final Map<String, String> proxyConfig = {};

    // 解析 scutil 的输出
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

    // 检查 HTTPEnable 是否为 1
    if (proxyConfig['HTTPEnable'] == '1') {
      final host = proxyConfig['HTTPProxy'];
      final port = proxyConfig['HTTPPort'];
      if (host != null && port != null) {
        return "$host:$port";
      }
    }
    // 也可以检查 HTTPSEnable，通常是一样的
    return null;
  }
}

/// 自定义 HttpOverrides
class _GlobalHttpOverrides extends HttpOverrides {
  final String proxyString;
  _GlobalHttpOverrides(this.proxyString);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "PROXY $proxyString; DIRECT";
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}