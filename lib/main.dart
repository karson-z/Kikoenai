import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/download/download_service.dart';
import 'package:kikoenai/core/utils/window/window_init_desktop.dart';
import 'package:media_kit/media_kit.dart';
import 'app/app.dart';
import 'config/environment_config.dart';
import 'core/service/audio/audio_service_ctrl.dart';
import 'core/service/audio/audio_service_media_kit.dart';
import 'core/service/proxy/auto_proxy_service.dart';
import 'core/storage/hive_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 强制透明
    statusBarIconBrightness: Brightness.dark, // 设置图标颜色：dark 为黑色图标，light 为白色图标
  ));
  await AppStorage.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await AudioServiceSingleton.init();
  await ProxyService.init();
  await DownloadService.init();
  debugPrint('开始检测最优服务器...');
  await EnvironmentConfig.selectBestServer();
  debugPrint('最终使用的 API 地址: ${EnvironmentConfig.baseUrl}');
  setupDesktopWindow();
  runApp(const ProviderScope(child: MyApp()));
}
