import 'dart:convert';

class JsonUtils {
  /// 将 dynamic 安全转换为 Map<String, dynamic>
  static Map<String, dynamic> toMap(dynamic input) {
    if (input == null) return {};

    // 本来就是 Map<String, dynamic>
    if (input is Map<String, dynamic>) {
      return input;
    }

    // json 字符串
    if (input is String) {
      final decoded = jsonDecode(input);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded.map(
              (key, value) => MapEntry(key.toString(), value),
        ));
      }
      throw Exception("JSON 字符串不是 Map 格式: $decoded");
    }

    // Map<dynamic, dynamic> 或 其他 Map 类型
    if (input is Map) {
      return Map<String, dynamic>.from(input.map(
            (key, value) => MapEntry(key.toString(), value),
      ));
    }

    throw Exception('无法将类型 ${input.runtimeType} 转成 Map<String, dynamic>');
  }
}