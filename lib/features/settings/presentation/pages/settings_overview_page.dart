import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/theme_view_model.dart';

/// Settings overview page: shows configurable categories.
class SettingsOverviewPage extends StatelessWidget {
  final VoidCallback? onOpenTheme;
  const SettingsOverviewPage({super.key, this.onOpenTheme});

  @override
  Widget build(BuildContext context) {
    // ensure ThemeViewModel is observed so the Shell updates dark mode switch
    context.watch<ThemeViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('配置列表',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题'),
            subtitle: const Text('主题模式与主题色设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenTheme ?? () => context.push(AppRoutes.settingsTheme),
          ),
        ),
      ],
    );
  }
}
