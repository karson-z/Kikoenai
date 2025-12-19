import 'package:kikoenai/core/constants/app_regex_str.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';

class RJPathUtils {
  const RJPathUtils._(); // 禁止实例化

  /// 校验 RJ 编号格式是否合法
  static bool isValidRJ(String rjCode) {
    if (!rjCode.startsWith('RJ') || rjCode.length != 10) {
      return false;
    }
    return int.tryParse(rjCode.substring(2)) != null;
  }

  /// 根据 RJ 编号计算所属目录编号
  ///
  /// throws [ArgumentError] 当 rjCode 非法时抛出
  static String computeDirectory(String rjCode) {
    _validateRJ(rjCode);

    final value = int.parse(rjCode.substring(2));

    // 向上取整到最近的 1000
    final dirValue = ((value + 999) ~/ 1000) * 1000;

    return 'RJ${dirValue.toString().padLeft(8, '0')}';
  }

  /// 构建完整路径：/目录/编号
  ///
  /// 示例：
  /// RJ01232781 -> /RJ01233000/RJ01232781
  static String buildPath(String rjCode) {
    final dir = computeDirectory(rjCode);
    return 'https://img.dlsite.jp/modpub/images2/work/doujin/$dir/${rjCode}_img_main.jpg';
  }
  static void _validateRJ(String rjCode) {
    if (!isValidRJ(rjCode)) {
      throw ArgumentError('Invalid RJ code: $rjCode');
    }
  }
  static String? getRjcode(String path) {
    final regExp = RegExp(RegexPatterns.workId);
    final match = regExp.firstMatch(path);

    if (match == null) {
      return null;
    }
    return match.group(0);
  }
}
