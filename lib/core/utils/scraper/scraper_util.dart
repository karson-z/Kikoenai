import 'package:uuid/uuid.dart';

class ScraperUtils {
  static String nameToUUID(String name) {
    const namespace = '699d9c07-b965-4399-bafd-18a3cacf073c';
    return const Uuid().v5(namespace, name);
  }

  static bool hasLetter(String str) {
    return str.contains(RegExp(r'[a-zA-Z]'));
  }

  /// 将 ID 转换为 6 位 RJ 编码字符串
  static String toRjCode(int id) {
    return id.toString().padLeft(6, '0');
  }
}