import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import '../../../../config/app_version_config.dart';
import '../../../../config/environment_config.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import '../widget/default_playlist_setting_tile.dart';
import '../widget/hive_switch_tile.dart';
import '../widget/service_selection.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Box<dynamic> get settingsBox => AppStorage.settingsBox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoggedIn = authState.value?.currentUser?.loggedIn ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SettingsSection(
            title: '通用偏好',
            children: [
              _ChevronTile(
                title: '语言',
                trailingText: '中文',
                onTap: () {
                  // TODO: 弹出语言选择逻辑
                },
              ),
              const _ServerSelectionTile(),
              _ChevronTile(
                title: '主题',
                onTap: () {
                  context.push(AppRoutes.settingsTheme);
                }
              ),
              _ChevronTile(
                title: '存储空间',
                onTap: () {
                  context.push(AppRoutes.settingsCache);
                }
              ),
              _ChevronTile(title: '邮箱',
                trailingText: isLoggedIn ? authState.value?.currentUser?.email : null,
                onTap: (){
                  //TODO 等待实现邮箱绑定功能
                },
              )
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: '播放与内容',
            children: [
              const DefaultPlaylistSettingTile(),
              const HiveSwitchTile(
                title: '忽略音频焦点',
                storageKey: StorageKeys.ignoreAudioFocus,
                defaultValue: false,
              ),
              _ChevronTile(
                title: '音频类型偏好',
                trailingText: 'wav > mp3...',
                onTap: () {
                  // TODO: 弹出选择逻辑
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: '搜索',
            children: [
              _ChevronTile(
                title: '全局筛选',
                trailingText: '筛选/屏蔽关键词',
                onTap: () {
                  // TODO: 弹出选择逻辑
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SettingsSection(
            title: '关于',
            children: [
              _ChevronTile(
                title: '关于Kikoenai',
                onTap: () => context.push(AppRoutes.about),
              ),
              _ChevronTile(
                title: '系统权限',
                onTap: () => context.push(AppRoutes.settingsPermission),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Center(
            child: isLoggedIn
                ? _buildLogoutButton(context, ref, theme)
                : _buildLoginButton(context, theme),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${VersionConfig.appName} version ${VersionConfig.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建退出登录按钮
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        // 执行退出登录逻辑
        await ref.read(authNotifierProvider.notifier).logout();

        if (context.mounted) {
          // 1. 弹出成功提示
          KikoenaiToast.success('已安全退出登录', context: context);
          // 2. 跳转回个人中心 (根据你的路由定义，通常是 user 页)
          context.go(AppRoutes.user);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Text(
          '退出登录',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  /// 构建立即登录按钮
  Widget _buildLoginButton(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(AppRoutes.login),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Text(
          '立即登录',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ========================================================
// UI 私有组件封装 (保持代码整洁)
// ========================================================

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
            child: Text(
              title!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChevronTile extends StatelessWidget {
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  const _ChevronTile({
    required this.title,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerSelectionTile extends ConsumerWidget {
  const _ServerSelectionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentServer = ref.watch(serverSettingsProvider);
    final displayLabel = EnvironmentConfig.getDisplayName(currentServer);

    return _ChevronTile(
      title: '选择服务器',
      trailingText: displayLabel,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          builder: (context) => const ServerSelectionModal(),
        );
      },
    );
  }
}