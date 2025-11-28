import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:kikoenai/core/service/audio_service.dart';
import 'package:kikoenai/core/service/cache_service.dart';
import 'package:kikoenai/core/utils/window/window_init_desktop.dart';
import 'package:kikoenai/core/widgets/layout/app_global_interceptor.dart';
import 'app/app.dart';
import 'core/common/shared_preferences_service.dart';
import 'core/storage/hive_storage.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,            // default: true  - dependency: media_kit_libs_linux
      windows: true,          // default: true  - dependency: media_kit_libs_windows_audio
      android: true,          // default: false - dependency: media_kit_libs_android_audio
      iOS: true,              // default: false - dependency: media_kit_libs_ios_audio
      macOS: true,            // default: false - dependency: media_kit_libs_macos_audio
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  await AudioServiceSingleton.init();
  final storage = await HiveStorage.getInstance();
  CacheService.initialize(storage);
  await SharedPreferencesService.init();
  setupDesktopWindow();
  runApp(const ProviderScope(child: GlobalBackInterceptor(child: MyApp())));
}
