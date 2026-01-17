import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:kikoenai/core/service/audio_service.dart';
import 'package:kikoenai/core/utils/window/window_init_desktop.dart';
import 'app/app.dart';
import 'config/environment_config.dart';
import 'core/service/auto_proxy_service.dart';
import 'core/storage/hive_key.dart';
import 'core/storage/hive_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,            // default: true  - dependency: media_kit_libs_linux
      windows: true,          // default: true  - dependency: media_kit_libs_windows_audio
      android: true,          // default: false - dependency: media_kit_libs_android_audio
      iOS: true,              // default: false - dependency: media_kit_libs_ios_audio
      macOS: true,            // default: false - dependency: media_kit_libs_macos_audio
    );
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 强制透明
    statusBarIconBrightness: Brightness.dark, // 设置图标颜色：dark 为黑色图标，light 为白色图标
    // 或者是：statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await AudioServiceSingleton.init();
  await AppStorage.init();
  await ProxyService.init();
  print('开始检测最优服务器...');
  await EnvironmentConfig.selectBestServer();
  print('最终使用的 API 地址: ${EnvironmentConfig.baseUrl}');
  setupDesktopWindow();
  runApp(const ProviderScope(child: MyApp()));
}
