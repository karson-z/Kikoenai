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
  static String toRjCode(int id, {int length = 7}) {
    // padLeft 会填充到指定的总长度（不含前缀）
    // 如果你希望长度是指“数字部分的长度”，直接传参即可
    return 'RJ0${id.toString().padLeft(length, '0')}';
  }
  static String getFolderCode(int id) {
    int folderId = (id % 1000 == 0) ? id : (id ~/ 1000) * 1000 + 1000;
    return 'RJ0${folderId.toString().padLeft(7, '0')}';
  }
}