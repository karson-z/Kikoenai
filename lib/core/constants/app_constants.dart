import 'package:flutter/material.dart';

class AppConstants {
  static const tokenKey = 'TOKEN';
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  // Layout
  static const double kPadding = 16.0;
  static const double kRadius = 12.0;
  static const double kAppBarHeight = 58.0;
  // 定义一个简单的断点常量，解耦对外部业务逻辑的依赖
  static const double kMobileBreakpoint = 600.0;
  // 底部导航栏高度
  static const double kAppBottomNavHeight = 68.0;
  // 迷你播放条高度
  static const double kMiniPlayerHeight = 75;

  static const String aoAudioTrack = 'audiotrack';
  static const String aoAAudio = 'aaudio';
  static const String aoOpenSLES = 'opensles';

  static const List<String> validAoModes = [
    aoAudioTrack,
    aoAAudio,
    aoOpenSLES,
  ];

  // 默认模式
  static const String defaultAoMode = aoAudioTrack;

}