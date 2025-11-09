import 'package:flutter/foundation.dart';

/// 环境配置类，用于处理不同平台的配置差异
class EnvironmentConfig {
  /// 获取基础API URL
  /// - Windows: 使用 localhost
  /// - Android 模拟器: 使用 10.0.2.2 (Android Emulator 映射到主机localhost)
  /// - 其他平台: 默认使用 localhost
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:8081';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 模拟器不能直接访问 localhost，需要使用 10.0.2.2
      return 'http://10.0.2.2:8081';
    } else {
      // 默认使用 localhost 作为基础URL
      return 'http://localhost:8081';
    }
  }

  /// 获取API超时时间（毫秒）
  static const int apiTimeoutMs = 30000;

  /// 是否为开发环境
  static const bool isDev = true;
}
