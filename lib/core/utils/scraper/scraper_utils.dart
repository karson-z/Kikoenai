import 'package:uuid/uuid.dart';

/// App 爬虫工具方法。
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

  /// 将数字 ID 转换为 DLsite 作品编号。
  ///
  /// DLsite 只接受 6 位或 8 位数字。不足 6 位补到 6 位，
  /// 6 位以上的奇数位补一个零，例如 `97514` → `RJ097514`、
  /// `123456` → `RJ123456`、`1234567` → `RJ01234567`。
  static String toRjCode(int id) {
    var digits = id.toString();
    if (digits.length < 6) digits = digits.padLeft(6, '0');
    if (digits.length.isOdd) digits = '0$digits';
    return 'RJ$digits';
  }
}
