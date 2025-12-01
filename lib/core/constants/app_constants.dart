import 'package:flutter/material.dart';
import 'package:kikoenai/config/environment_config.dart';

class AppConstants {
  static const String appName = 'Kikoenai';
  static const tokenKey = 'TOKEN';
  static const userInfoKey = 'USER_INFO';

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  // Layout
  static const double kPadding = 16.0;
  static const double kRadius = 12.0;
  static const double kAppBarHeight = 64.0;
  // 定义一个简单的断点常量，解耦对外部业务逻辑的依赖
  static const double kMobileBreakpoint = 600.0;
  // Network - 使用平台特定的基础URL
  static String get apiBaseUrl => '${EnvironmentConfig.baseUrl}/api';
}
