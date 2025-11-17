import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme_view_model.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 ThemeNotifier 的状态
    final themeStateAsync = ref.watch(themeNotifierProvider);

    // 获取 ThemeMode，如果状态还在 loading 或 error，默认 system
    final themeMode = themeStateAsync.maybeWhen(
      data: (value) => value.mode,
      orElse: () => ThemeMode.system,
    );

    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? '切换为浅色模式' : '切换为深色模式',
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      onPressed: () {
        // 切换主题
        ref.read(themeNotifierProvider.notifier).toggleLightDark();
      },
    );
  }
}
