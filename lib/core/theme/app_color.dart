import 'package:flutter/material.dart';

/// 全局颜色常量定义
class AppColors {
  // 基础色
  static const Color primary = Color(0xFF4CAF50);

  // ----------------- 亮色模式 (Light) -----------------
  static const Color lightBackground = Colors.white;
  // 新增：iOS 风格的分组背景色（浅灰），用于 BottomSheet 底色
  static const Color lightGroupedBackground = Color(0xFFF7F8FA);
  static const Color lightText = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF666666); // 调整为更柔和的灰色
  static const Color lightCard = Colors.white;
  static const Color lightShadow = Color.fromARGB(20, 0, 0, 0); // 调淡阴影
  static const Color lightDivider = Color(0xFFEEEEEE); // 新增：分割线

  // ----------------- 暗色模式 (Dark) -----------------
  static const Color darkBackground = Colors.black;
  // 新增：iOS 风格的分组背景色（深灰/黑），用于 BottomSheet 底色
  static const Color darkGroupedBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E); // 稍微亮一点的深灰，用于卡片
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkShadow = Colors.black87;
  static const Color darkDivider = Colors.white12; // 新增：分割线

  // 通用
  static const Color transparent = Colors.transparent;
}