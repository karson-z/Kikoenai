import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'tray_service.dart';

Future<void> setupDesktopWindow() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;

  await windowManager.ensureInitialized();

  // 初始化系统托盘（最小化到托盘功能依赖此）
  await TrayService.instance.init();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 860),
    minimumSize: Size(840, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAspectRatio(4 / 3);
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.setPreventClose(true);
}