import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/features/settings/presentation/pages/settings_cache_manager.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/theme_view_model.dart';

/// 设置总览页
class SettingsOverviewPage extends ConsumerWidget {
  final VoidCallback? onOpenTheme;

  const SettingsOverviewPage({super.key, this.onOpenTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听主题状态
    ref.watch(themeNotifierProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '配置列表',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('缓存管理'),
            subtitle: const Text('查看与清理缓存'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showCacheManagerSheet(context, boxNames: BoxNames.values), // 跳转到缓存管理页
          ),
        ),
      ],
    );
  }
}
