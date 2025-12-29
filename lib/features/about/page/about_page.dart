import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. 引入 Riverpod
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_version_config.dart';
import '../../../core/widgets/layout/app_toast.dart';
// 假设这是你存放 provider 的路径，请根据实际情况修改引入
import '../provider/about_provider.dart';

// 2. 将 StatefulWidget 改为 ConsumerStatefulWidget
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

// 3. 将 State 改为 ConsumerState
class _AboutPageState extends ConsumerState<AboutPage> {

  @override
  void initState() {
    super.initState();
  }

  /// 打开外部链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      KikoenaiToast.error('无法打开链接: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 4. 监听更新 Provider 的状态
    // 当 checkUpdate 开始执行时，state 会变为 loading，isLoading 为 true
    final updateState = ref.watch(appUpdateProvider);
    final isCheckingUpdate = updateState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          // 1. 顶部 App 信息区域
          Center(
            child: Column(
              children: [
                // Logo 图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/muzumi.jpg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // App 名称
                Text(
                  VersionConfig.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 版本号
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Version ${VersionConfig.version}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // 2. 列表选项
          _buildSectionHeader(context, '信息'),
          _buildListTile(
            context,
            icon: Icons.code_rounded,
            title: '代码仓库',
            subtitle: 'Github',
            onTap: () => _launchUrl(VersionConfig.sourceUrl),
          ),
          _buildListTile(
            context,
            icon: Icons.gavel_rounded,
            title: '开源许可证',
            onTap: () => showLicensePage(
              context: context,
              applicationName: VersionConfig.appName,
              applicationVersion: VersionConfig.version,
            ),
          ),
          _buildDivider(),
          _buildSectionHeader(context, '维护'),

          // 5. 修改“检查更新”项
          _buildListTile(
            context,
            icon: Icons.system_update_rounded,
            title: '检查更新',
            // 如果正在检查，显示状态文字
            subtitle: isCheckingUpdate ? '正在检查新版本...' : '当前版本 ${VersionConfig.version}',
            // 如果正在检查，显示 Loading 圈，否则显示箭头
            trailing: isCheckingUpdate
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : null, // null 会使用默认的 chevron_right
            // 如果正在检查，禁止点击
            onTap: isCheckingUpdate
                ? () {}
                : () {
              // 调用 Provider 进行手动检查
              ref.read(appUpdateProvider.notifier).checkUpdate(isManual: true);
            },
          ),

          const SizedBox(height: 40),
          // 底部版权信息
          Center(
            child: Text(
              'Copyright © 2025 ${VersionConfig.appName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// 稍微修改了 _buildListTile 以支持自定义 trailing
  Widget _buildListTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
        Widget? trailing, // 新增参数
      }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      // 如果传入了 trailing 则使用传入的，否则显示默认箭头
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      indent: 24,
      endIndent: 24,
      height: 32,
      thickness: 0.5,
    );
  }
}