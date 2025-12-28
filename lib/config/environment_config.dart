import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/service/cache_service.dart';
import '../core/utils/network/api_client.dart'; // 请确保路径正确

class EnvironmentConfig {
  static const String _defaultUrl = 'https://api.asmr-200.com';
  static String _currentBaseUrl = _defaultUrl;
  static String get baseUrl => _currentBaseUrl;
  static List<String> get candidates => _candidates;

  static const List<String> _candidates = [
    'https://api.asmr-200.com',
    'https://api.asmr.one',
    'https://api.asmr-100.com',
    'https://api.asmr-300.com',
  ];

  /// 辅助方法：URL转显示名称
  static String getDisplayName(String url) {
    if (url.contains('asmr-200')) return 'Mirror-200 (推荐)';
    if (url.contains('asmr.one')) return 'Main (ASMR.ONE)';
    if (url.contains('asmr-100')) return 'Mirror-100';
    if (url.contains('asmr-300')) return 'Mirror-300';
    return 'Unknown Server';
  }

  /// 核心初始化逻辑
  static Future<void> selectBestServer() async {
    // ------------------------------------------------------
    // 1. 优先检查缓存 (增加熔断机制)
    // ------------------------------------------------------
    try {
      final cachedHost = await CacheService.instance.getCurrentHost();

      if (cachedHost != null && cachedHost.isNotEmpty) {
        // 【核心修改】：增加 .timeout()
        // 意思是：尝试检查缓存节点，但如果超过 2.5秒 还没结果，就抛出 TimeoutException
        final isCachedAlive = await ApiClient.instance
            .checkHealth(cachedHost)
            .timeout(const Duration(milliseconds: 2500));

        if (isCachedAlive) {
          await _updateGlobalConfig(cachedHost);
          print('缓存节点 [$cachedHost] 正常，跳过全局优选');
          return;
        } else {
          print('缓存节点 [$cachedHost] 已失效，转入全局自动优选...');
        }
      }
    } catch (e) {
      // 无论是超时(TimeoutException)还是其他错，都打印日志并继续向下执行
      print('️缓存节点检查跳过 (原因: $e)');
    }

    // ------------------------------------------------------
    // 2. 赛跑逻辑 (增加兜底熔断)
    // ------------------------------------------------------
    final completer = Completer<String>();
    int failCount = 0;

    // 并发发起请求
    for (final domain in _candidates) {
      ApiClient.instance.checkHealth(domain).then((isSuccess) {
        if (isSuccess && !completer.isCompleted) {
          completer.complete(domain);
        } else {
          failCount++;
          // 只有当所有都失败时，才完成为默认值
          if (failCount == _candidates.length && !completer.isCompleted) {
            print('️所有节点检测失败 (逻辑层)，使用默认节点');
            completer.complete(_defaultUrl);
          }
        }
      });
    }

    // 【核心修改】：等待赛跑结果时，也加上强制超时
    // 如果 5秒 内 4个服务器没一个能返回结果（比如断网了），强制使用默认值
    try {
      final bestHost = await completer.future.timeout(const Duration(seconds: 5));
      print('✅ 全局优选完成，选中节点: $bestHost');
      await _updateGlobalConfig(bestHost);
    } catch (e) {
      print('⚠️ 全局优选超时或全失败，强制兜底: $_defaultUrl');
      await _updateGlobalConfig(_defaultUrl);
    }
  }

  /// 统一更新配置的方法 (改为 Public 以便 Provider 调用)
  static Future<void> updateGlobalConfig(String host) async {
    await _updateGlobalConfig(host);
  }

  static Future<void> _updateGlobalConfig(String host) async {
    // 1. 更新静态变量
    if (_candidates.contains(host) || host == _defaultUrl) {
      _currentBaseUrl = host;
    }

    // 2. 更新 ApiClient (至关重要！否则发请求还是旧地址)
    ApiClient.instance.updateBaseUrl(host);

    // 3. 持久化
    try {
      await CacheService.instance.saveCurrentHost(host);
    } catch (e) {
      print('⚠️ 保存最优节点失败: $e');
    }
  }
}
final serverSettingsProvider = NotifierProvider<ServerSettingsNotifier, String>(() {
  return ServerSettingsNotifier();
});

class ServerSettingsNotifier extends Notifier<String> {
  @override
  String build() {
    return EnvironmentConfig.baseUrl;
  }

  /// 用户手动切换服务器
  Future<void> changeServer(String newUrl) async {
    await EnvironmentConfig.updateGlobalConfig(newUrl);

    // 更新 UI 状态
    state = newUrl;
  }
}