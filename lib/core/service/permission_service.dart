import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static int? _cachedSdk;

  /// 读取 Android SDK 版本（使用 device_info_plus）
  static Future<int> get androidSdk async {
    if (!Platform.isAndroid) return 30;

    // 缓存避免频繁调用
    if (_cachedSdk != null) return _cachedSdk!;

    final info = await DeviceInfoPlugin().androidInfo;
    _cachedSdk = info.version.sdkInt;
    return _cachedSdk!;
  }

  /// 返回当前设备适用的权限列表
  static Future<Map<String, Permission>> getAvailablePermissions() async {
    final Map<String, Permission> data = {};

    if (!Platform.isAndroid) return data;

    final sdk = await androidSdk;

    // 通知
    data["通知权限"] = Permission.notification;

    // Android 13+ (SDK 33)
    if (sdk >= 33) {
      data["读取音频"] = Permission.audio;
      data["读取图片"] = Permission.photos;
      data["读取视频"] = Permission.videos;
    } else {
      // Android 12 及以下
      data["读存储"] = Permission.storage;
      data["写存储"] = Permission.manageExternalStorage;
    }

    // 特殊权限
    data["悬浮窗"] = Permission.systemAlertWindow;

    return data;
  }

  /// 检查所有权限（例如 App 启动时调用）
  static Future<Map<String, bool>> checkAllPermissions() async {
    final perms = await getAvailablePermissions();
    final results = <String, bool>{};

    for (final entry in perms.entries) {
      final status = await entry.value.status;
      results[entry.key] = status.isGranted;
    }

    return results;
  }

  /// 请求单个权限
  static Future<bool> requestPermission(Permission p) async {
    final result = await p.request();
    return result.isGranted;
  }

  /// 是否开启通知（用于检查是否禁用通知渠道）
  static Future<bool> isNotificationChannelEnabled() async {
    final result = await Permission.notification.status;
    return result.isGranted;
  }
}
