import 'package:flutter/material.dart';

/// 所有的筛选枚举都需要实现这个接口（或被包装成这个接口）
abstract class FilterOptionItem {
  String get label;       // UI显示的文字，如 "R18", "中文", "短篇"
  String get value;       // 传给API的值
  Color get activeColor;  // 选中时的主题色
}

class SimpleFilterOption implements FilterOptionItem {
  @override
  final String label;
  @override
  final String value;
  @override
  final Color activeColor;

  const SimpleFilterOption({
    required this.label,
    required this.value,
    this.activeColor = Colors.blueAccent
  });
}