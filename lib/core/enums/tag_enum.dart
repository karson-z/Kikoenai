enum TagType {
  // 基础标签
  tag("tag"),

  // 对应图片中的 $va (你之前写的是 author，建议改为 va 以匹配语法)
  va("va"),

  // 对应图片中的 $circle
  circle("circle"),

  // 对应图片中的 $age
  age("age"),

  // --- 以下是根据图片补全的新类型 ---

  // 对应图片中的 $duration (时长)
  duration("duration"),

  // 对应图片中的 $rate (评分)
  rate("rate"),

  // 对应图片中的 $price (价格)
  price("price"),

  // 对应图片中的 $sell (销量)
  sell("sell"),

  // 对应图片中的 $lang (语言)
  lang("lang");

  final String stringValue;

  const TagType(this.stringValue);

  String toApiString() {
    return stringValue;
  }

  /// 可选：添加一个辅助方法，用于从字符串解析枚举
  static TagType? fromString(String key) {
    for (var type in TagType.values) {
      if (type.stringValue == key) {
        return type;
      }
    }
    return null;
  }
}