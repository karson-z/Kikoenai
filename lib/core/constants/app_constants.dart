import 'package:flutter/material.dart';
import 'package:name_app/config/environment_config.dart';

class AppConstants {
  static const String appName = 'PubAssistant Demo';
  static const tokenKey = 'TOKEN';
  static const userInfoKey = 'USER_INFO';

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  // Layout
  static const double kPadding = 16.0;
  static const double kRadius = 12.0;
  static const double kAppBarHeight = 64.0;
  // Network - 使用平台特定的基础URL
  static String get apiBaseUrl => '${EnvironmentConfig.baseUrl}/api';
}
