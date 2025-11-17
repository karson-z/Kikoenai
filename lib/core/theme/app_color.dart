import 'package:flutter/material.dart';

/// 全局颜色常量定义，不依赖 Theme
class AppColors {
  // 基础色（可以由 seed 来控制，但保留默认值）
  static const Color primary = Color(0xFF4CAF50);

  // 亮色模式专用
  static const Color lightBackground = Colors.white;
  static const Color lightText = Colors.black;
  static const Color lightTextSecondary = Colors.black54;
  static const Color lightCard = Colors.white;
  static const Color lightShadow = Color.fromARGB(70, 0, 0, 0);

  // 暗色模式专用
  static const Color darkBackground = Colors.black;
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Colors.white54;
  static const Color darkShadow = Colors.black87;

  // 通用
  static const Color transparent = Colors.transparent;
}
