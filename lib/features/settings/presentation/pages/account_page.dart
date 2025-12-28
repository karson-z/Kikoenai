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
    // 1. 监听 AuthNotifier 获取当前状态
    // 使用 .when 处理加载中、错误和数据三种状态，体验更细腻
    final authStateAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号管理'),
        centerTitle: true,
      ),
      // 2. 仅在“未登录”状态下显示悬浮按钮，引导去登录
      // 如果已登录，通常不需要这个按钮，或者可以改成“联系客服”等其他功能
      floatingActionButton: authStateAsync.value?.currentUser == null
          ? FloatingActionButton.extended(
        onPressed: () {
          // 跳转到登录页 (需确保路由配置了 '/login')
          context.push(AppRoutes.login);
        },
        icon: const Icon(Icons.login),
        label: const Text('去登录'),
      )
          : null,
      body: authStateAsync.when(
        data: (state) {
          final user = state.currentUser;
          final isLogin = user != null;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 头部卡片：显示用户信息或游客信息
              _buildProfileHeader(context, user),

              const SizedBox(height: 24),

              // 菜单列表
              _buildMenuItem(
                icon: Icons.settings,
                title: '通用设置',
                onTap: () {
                  context.push(AppRoutes.settingsComment);
                },
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: '关于应用',
                onTap: () {},
              ),

              // 如果已登录，显示退出按钮
              if (isLogin) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    // 显示确认弹窗
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('提示'),
                        content: const Text('确定要退出登录吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('退出', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      // 执行登出逻辑
                      await ref.read(authNotifierProvider.notifier).logout();
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('退出登录', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ],
          );
        },
        // 加载中显示骨架屏或 Loading
        loading: () => const Center(child: CircularProgressIndicator()),
        // 错误状态
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  /// 构建顶部用户信息卡片
  Widget _buildProfileHeader(BuildContext context, User? user) {
    final isLogin = user != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // 头像区域
            CircleAvatar(
              radius: 36,
              backgroundColor: isLogin
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.shade200,
              // 如果 User 有 avatarUrl 可以在这里加载网络图片
              // backgroundImage: isLogin && user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: Icon(
                isLogin ? Icons.account_circle : Icons.person_outline,
                size: 40,
                color: isLogin ? Theme.of(context).primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),

            // 信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLogin ? (user.name ?? '未命名用户') : '游客用户',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLogin ? 'UID: ${user.recommenderUuid ?? "未知"}' : '当前未登录，功能受限',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 封装列表项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}