import 'package:uuid/uuid.dart';

/// 爬虫工具方法（迁移自 `kikoenai_app/lib/core/utils/scraper/scraper_util.dart`）。
class ScraperUtils {
  /// 基于固定 namespace 生成稳定 UUID v5
  static String nameToUUID(String name) {
    const namespace = '699d9c07-b965-4399-bafd-18a3cacf073c';
    return const Uuid().v5(namespace, name);
  }

  /// 字符串中是否包含拉丁字母
  static bool hasLetter(String str) {
    return str.contains(RegExp(r'[a-zA-Z]'));
  }

  /// 将数字 ID 转换为 RJ 编码（如 `123456` → `RJ0123456`）
  static String toRjCode(int id, {int length = 7}) {
    return 'RJ0${id.toString().padLeft(length, '0')}';
  }
}
