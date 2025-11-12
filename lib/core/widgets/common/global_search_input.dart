import 'package:flutter/material.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:provider/provider.dart';

class GlobalSearchInput extends StatelessWidget {
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlobalSearchInput({
    super.key,
    this.onSubmitted,
    this.onChanged,
    this.hintText = '搜索内容...',
    this.borderRadius = 25,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.themeMode == ThemeMode.dark;

    // 背景色根据主题切换
    final bgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: padding,
        child: TextField(
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(Icons.search, color: iconColor),
            filled: false, // 内部不再填充白色
            border: InputBorder.none, // 去掉 TextField 自带边框
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}
