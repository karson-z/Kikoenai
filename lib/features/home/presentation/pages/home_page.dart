import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_view_model.dart';

class HomePage extends ConsumerWidget {
  final ValueChanged<int>? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听主题状态，使暗黑模式切换响应式
    final themeStateAsync = ref.watch(themeNotifierProvider);
    final isDark = themeStateAsync.maybeWhen(
      data: (value) => value.mode == ThemeMode.dark,
      orElse: () => false,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome to PubAssistant Demo',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onNavigate?.call(2),
            child: const Text('Go to Auth'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => onNavigate?.call(1),
            child: const Text('Go to User'),
          ),
        ],
      ),
    );
  }
}
