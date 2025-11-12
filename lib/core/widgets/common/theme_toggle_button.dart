import 'package:flutter/material.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:provider/provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? '切换为浅色模式' : '切换为深色模式',
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      onPressed: themeVM.toggleLightDark,
    );
  }
}
