import 'dart:ui';

import 'package:flutter/material.dart';

/// 年龄分级枚举
enum AgeRatingEnum {
  all('general', '全年龄'),
  mature('r15', 'R-15'),
  adult("adult", 'R-18');

  final String value;
  final String label;

  const AgeRatingEnum(this.value, this.label);

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
  static Color ageRatingColor(AgeRatingEnum rating) {
    switch (rating) {
      case AgeRatingEnum.all:
        return Colors.green.withAlpha(160);
      case AgeRatingEnum.mature:
        return Colors.orange.withAlpha(160);
      case AgeRatingEnum.adult:
        return Colors.red.withAlpha(160);
    }
  }
  /// 一键拿颜色
  static Color ageRatingColorByValue(String? value) {
    return ageRatingColor(AgeRatingEnum.fromValue(value));
  }
  /// 获取所有选项
  static List<Map<String, dynamic>> get options => AgeRatingEnum.values
      .map((e) => {'label': e.label, 'value': e.value})
      .toList();

  /// 获取映射（类似 TS 的 AgeRatingMap）
  static Map<String, String> get map =>
      {for (var e in AgeRatingEnum.values) e.value: e.label};
}
