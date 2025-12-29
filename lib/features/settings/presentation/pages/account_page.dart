import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import '../../../user/data/models/user.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号管理'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: authStateAsync.when(
        data: (state) {
          final user = state.currentUser;
          final isLogin = user != null;

          return LayoutBuilder(builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24.0 : 16.0,
                    vertical: 16.0,
                  ),
                  children: [
                    // 头部信息（无背景）
                    _buildProfileHeader(context, user, isDesktop),

                    const SizedBox(height: 24),

                    // 分组标题
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8), // 稍微增加左边距对齐文字
                      child: Text(
                        '常规',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 菜单组（无背景，看起来就是直接排列的列表）
                    Card(
                      elevation: 0, // 去掉阴影
                      color: Colors.transparent, // [修改] 背景透明
                      margin: EdgeInsets.zero, // 去掉卡片默认外边距
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.settings_rounded,
                            title: '通用设置',
                            onTap: () {
                              context.push(AppRoutes.settingsComment);
                            },
                          ),
                          // [修改] 分割线颜色稍微调淡一点，因为背景没了
                          Divider(
                              height: 1,
                              indent: 56,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2)
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.info_outline_rounded,
                            title: '关于应用',
                            onTap: () {
                              context.push(AppRoutes.about);
                            },
                          ),
                        ],
                      ),
                    ),

                    // 退出登录按钮
                    if (isLogin) ...[
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton.tonalIcon(
                          onPressed: () => _handleLogout(context, ref),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('退出登录'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5), //稍微淡一点
                            foregroundColor: Theme.of(context).colorScheme.error,
                            elevation: 0, // 按钮也去掉阴影，保持一致风格
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          });
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
      floatingActionButton: _shouldShowFab(context, authStateAsync.value?.currentUser)
          ? FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.login),
        elevation: 2, // FAB 保留一点点阴影以便区分
        icon: const Icon(Icons.login),
        label: const Text('去登录'),
      )
          : null,
    );
  }

  bool _shouldShowFab(BuildContext context, User? user) {
    if (user != null) return false;
    final width = MediaQuery.sizeOf(context).width;
    return width <= 600;
  }

  /// 构建顶部用户信息（无背景风格）
  Widget _buildProfileHeader(BuildContext context, User? user, bool isDesktop) {
    final isLogin = user != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0, // [修改] 去掉阴影
      color: Colors.transparent, // [修改] 背景透明
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0), // 减少一点内边距
        child: Row(
          children: [
            // 头像
            Container(
              child: CircleAvatar(
                radius: 40,
                // [修改] 默认背景色改淡
                backgroundColor: Colors.transparent,
                child: Icon(
                  isLogin ? Icons.account_circle : Icons.person_outline,
                  size: 64,
                  color: isLogin ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLogin ? (user.name ?? '用户') : '游客访客',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      // [修改] 统一使用 onSurface，因为背景是透明的
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLogin ? 'UUID: ${user.recommenderUuid ?? "未知"}' : '登录以同步数据',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            if (!isLogin && isDesktop)
              FilledButton.tonal(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('立即登录'),
              )
          ],
        ),
      ),
    );
  }

  /// 封装列表项
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell( // [修改] 使用 InkWell 代替 Material + ListTile，点击水波纹更自然
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // 增加内边距
        child: Row(
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                  icon,
                  // 使用 secondary 颜色，通常比 primary 柔和一点
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20
              ),
            ),
            const SizedBox(width: 16),
            // 标题
            Expanded(
              child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16
                  )
              ),
            ),
            // 箭头
            Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5)
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}