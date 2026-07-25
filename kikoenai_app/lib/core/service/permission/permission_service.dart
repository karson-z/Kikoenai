import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static int? _cachedAndroidSdk;

  static Future<int> get androidSdk async {
    if (!Platform.isAndroid) return 0; // 非 Android 统一返回 0
    if (_cachedAndroidSdk != null) return _cachedAndroidSdk!;
    final info = await DeviceInfoPlugin().androidInfo;
    return _cachedAndroidSdk = info.version.sdkInt;
  }

  /// 1. 获取【存储权限】状态 (完美封装 Android 10/11/13+ 的差异)
  static Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return await Permission.storage.isGranted;

    final sdk = await androidSdk;
    if (sdk >= 33) {
      // Android 13+ 废弃了普通存储权限，细分为音视频和图片
      return await Permission.audio.isGranted &&
          await Permission.photos.isGranted;
    } else if (sdk >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  /// 2. 请求【存储权限】
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return (await Permission.storage.request()).isGranted;

    final sdk = await androidSdk;
    // API 30 及以上 (包含 Android 11, 12, 13, 14+) 统一申请所有文件管理权限
    if (sdk >= 30) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      // API 29 及以下申请传统读写权限
      return (await Permission.storage.request()).isGranted;
    }
  }
  static Future<bool> checkNotificationPermission() async => await Permission.notification.isGranted;
  static Future<bool> requestNotificationPermission() async => (await Permission.notification.request()).isGranted;

  /// 跳转到系统设置页
  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}