import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_view_model.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    // Observe theme changes to keep shell's dark mode toggle reactive
    context.watch<ThemeViewModel>();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Welcome to PubAssistant Demo'),
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
