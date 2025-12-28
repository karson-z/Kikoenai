import 'package:flutter/material.dart';

import '../model/filter_option_item.dart';

/// 年龄分级枚举
enum AgeRatingEnum implements FilterOptionItem {
  // 定义枚举项，同时指定 value, label 和 基础颜色
  all('general', '全年龄', Colors.green),
  mature('r15', 'R-15', Colors.orange),
  adult("adult", 'R-18', Colors.red);

  @override
  final String value;
  @override
  final String label;

  // 专门用于筛选器的高亮颜色
  @override
  final Color activeColor;

  const AgeRatingEnum(this.value, this.label, this.activeColor);

  // --- 以下是你原本的业务逻辑方法 (保持不变或微调) ---

  /// 通过数值查找枚举
  static AgeRatingEnum fromValue(String? value) {
    return AgeRatingEnum.values.firstWhere(
          (e) => e.value == value,
      orElse: () => AgeRatingEnum.all,
    );
  }

  static String labelFromValue(String? value) {
    return fromValue(value).label;
  }

  /// 根据 label 查找 value
  static String valueFromLabel(String label) {
    try {
      return AgeRatingEnum.values.firstWhere(
            (e) => e.label == label,
      ).value;
    } catch (e) {
      return AgeRatingEnum.all.value;
    }
  }

  /// 获取特定透明度的颜色 (兼容你之前的逻辑)
  static Color ageRatingColor(AgeRatingEnum rating) {
    // 复用构造函数里的颜色，保持逻辑统一
    return rating.activeColor.withAlpha(160);
  }

  /// 一键拿颜色
  static Color ageRatingColorByValue(String? value) {
    return ageRatingColor(AgeRatingEnum.fromValue(value));
  }

  /// 获取所有选项
  static List<Map<String, dynamic>> get options => AgeRatingEnum.values
      .map((e) => {'label': e.label, 'value': e.value})
      .toList();

  /// 获取映射
  static Map<String, String> get map =>
      {for (var e in AgeRatingEnum.values) e.value: e.label};
}