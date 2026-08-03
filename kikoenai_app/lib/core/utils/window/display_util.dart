import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:window_manager/window_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DisplayUtils {
  DisplayUtils._();

  /// 进入全屏显示
  /// [isPortraitUp] 是否竖屏
  /// [lockOrientation] 移动端是否强制横屏
  static Future<void> enterFullScreen(bool isPortraitUp,{bool lockOrientation = true}) async {
    try {
      // 1. 桌面端处理
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        await windowManager.setFullScreen(true);
        return;
      }

      // 2. 移动端 UI 模式处理
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
      if (!lockOrientation) return;
      // 当前视频比例是否是9：16 且rotate 90° 是就是竖屏不是就是横屏
      isPortraitUp ? await setVertical() : await setLandscape();
    } catch (e) {
      KikoenaiLogger().e('DisplayUtils: failed to enter full screen. Error: $e');
    }
  }

  /// 退出全屏显示
  /// [lockOrientation] 移动端是否恢复竖屏
  static Future<void> exitFullScreen({bool lockOrientation = true}) async {
    try {
      // 1. 桌面端处理
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        await windowManager.setFullScreen(false);
      }

      // 2. 移动端处理
      if (Platform.isAndroid || Platform.isIOS) {
        SystemUiMode mode = SystemUiMode.edgeToEdge;

        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt < 29) {
            mode = SystemUiMode.manual;
          }
        }
        await SystemChrome.setEnabledSystemUIMode(
          mode,
          overlays: SystemUiOverlay.values,
        );
        await setVertical();
      }
    } catch (e) {
      debugPrint('DisplayUtils: failed to exit full screen. Error: $e');
    }
  }

  /// 强制横屏
  static Future<void> setLandscape() async {
    try {
      if (kIsWeb) {
        // Web 端通常需要通过 dart:html 的 document 触发，此处为占位
        return;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (e) {
      debugPrint('DisplayUtils: failed to set landscape. Error: $e');
    }
  }

  /// 强制竖屏
  static Future<void> setVertical() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    } catch (e) {
      debugPrint('DisplayUtils: failed to set vertical. Error: $e');
    }
  }

  /// 解除屏幕旋转限制（随系统传感器旋转）
  static Future<void> unlockScreenRotation() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([]);
      }
    } catch (e) {
      debugPrint('DisplayUtils: failed to unlock rotation. Error: $e');
    }
  }
}