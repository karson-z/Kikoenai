import 'package:disk_space_2/disk_space_2.dart';

class DeviceStorageUtil {
  /// 获取设备/磁盘总存储空间 (返回字节 Bytes)
  static Future<int> getTotalSpace() async {
    try {
      // 插件默认返回以 MB 为单位的浮点数
      final double? totalMB = await DiskSpace.getTotalDiskSpace;
      if (totalMB != null && totalMB > 0) {
        return (totalMB * 1024 * 1024).toInt();
      }
    } catch (e) {
      // 静默处理：忽略平台不支持或由于沙盒权限导致的异常
    }
    return 0;
  }

  /// 获取设备/磁盘可用存储空间 (返回字节 Bytes)
  static Future<int> getFreeSpace() async {
    try {
      final double? freeMB = await DiskSpace.getFreeDiskSpace;
      if (freeMB != null && freeMB > 0) {
        return (freeMB * 1024 * 1024).toInt();
      }
    } catch (e) {
      // 同上
    }
    return 0;
  }
}