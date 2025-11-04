/// 年龄分级枚举
enum AgeRatingEnum {
  all(1, '全年龄'),
  mature(2, 'R-15'),
  adult(3, 'R-18');

  final int value;
  final String label;

  const AgeRatingEnum(this.value, this.label);

  /// 通过数值查找枚举
  static AgeRatingEnum fromValue(int? value) {
    return AgeRatingEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AgeRatingEnum.all,
    );
  }

  /// 获取所有选项
  static List<Map<String, dynamic>> get options => AgeRatingEnum.values
      .map((e) => {'label': e.label, 'value': e.value})
      .toList();

  /// 获取映射（类似 TS 的 AgeRatingMap）
  static Map<int, String> get map =>
      {for (var e in AgeRatingEnum.values) e.value: e.label};
}
