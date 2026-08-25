import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_version_config.dart';
import '../../../../core/service/permission/permission_provider.dart';

// 请替换为你的 provider 实际路径
// import 'permission_status_provider.dart';

class PermissionSettingsPage extends ConsumerStatefulWidget {
  const PermissionSettingsPage({super.key});

  @override
  ConsumerState<PermissionSettingsPage> createState() => _PermissionSettingsPageState();
}

class _PermissionSettingsPageState extends ConsumerState<PermissionSettingsPage> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // 核心魔法：监听 App 从后台(系统设置)切回前台的事件，自动刷新权限状态！
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        ref.read(permissionStatusProvider.notifier).refresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(permissionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统权限', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (statuses) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 顶部提示文案
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '为提供更好的体验，${VersionConfig.appName}在特定场景可能需要申请以下手机权限,PC端的话无需申请任何权限',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),

              // 权限卡片列表
              _buildPermissionBlock(
                context: context,
                title: '存储空间信息',
                description: '用于下载音频视频, 扫描资源等操作。关闭该权限后本地媒体功能将不可用',
                isGranted: statuses['storage'] ?? false,
                onTap: () => ref.read(permissionStatusProvider.notifier).handleRequest('storage'),
              ),
              _buildPermissionBlock(
                context: context,
                title: '通知权限',
                description: '帮助你第一时间接收到${VersionConfig.appName}的通知信息',
                isGranted: statuses['notification'] ?? false,
                onTap: () => ref.read(permissionStatusProvider.notifier).handleRequest('notification'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 内部构建权限卡片 + 底部悬挂描述文字 的组件
  Widget _buildPermissionBlock({
    required BuildContext context,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 卡片本身
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isGranted ? null : onTap, // 如果已开启，禁止再次点击，否则去设置
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    isGranted ? '已开启' : '去设置',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, // 均使用暗色字还原截图质感
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. 卡片底部的灰色描述文字
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, top: 12, bottom: 28),
          child: Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}