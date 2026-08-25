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

  /// 获取扫描本地文件所需的存储权限状态。
  static Future<bool> checkStoragePermission() async {
    // iOS/macOS/Windows 等平台由系统文件选择器授予所选目录的访问能力，
    // 不存在 Android 的“所有文件访问权限”。
    if (!Platform.isAndroid) return true;

    final sdk = await androidSdk;
    if (sdk >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  /// 请求扫描本地文件所需的存储权限。
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdk = await androidSdk;
    // Android 11 及以上统一申请所有文件管理权限，和状态检查保持一致。
    if (sdk >= 30) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    // Android 10 及以下申请传统读写权限。
    return (await Permission.storage.request()).isGranted;
  }

  static Future<bool> checkNotificationPermission() async =>
      await Permission.notification.isGranted;
  static Future<bool> requestNotificationPermission() async =>
      (await Permission.notification.request()).isGranted;

  /// 跳转到系统设置页
  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}
