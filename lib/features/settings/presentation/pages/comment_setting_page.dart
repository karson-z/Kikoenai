import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
// 引入之前的配置和 Provider
import '../../../../config/environment_config.dart';
import '../../../../core/storage/hive_storage.dart';
import '../widget/default_playlist_setting_tile.dart';
import '../widget/service_selection.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  Box<dynamic> get settingsBox => AppStorage.settingsBox;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通用设置'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: const [
          // 1. 语言 (UI 占位)
          _PlaceholderDropdownTile(
            icon: Icons.language,
            title: '语言',
            subtitle: '语言 / Language / 言語',
            value: '中文',
            items: ['中文', 'English', '日本語'],
          ),
          _Divider(),

          // 3. 效果音偏好 (UI 占位 - Switch)
          _PlaceholderSwitchTile(
            icon: Icons.waves, // 或者 Icons.air
            title: '效果音偏好',
            subtitle: '优先进入包含效果音的文件夹',
            value: true,
          ),
          _Divider(),

          // 4. 音频类型偏好 (UI 占位 - 纯文本展示)
          _StaticTextTile(
            icon: Icons.format_list_numbered,
            title: '音频类型偏好',
            subtitle: '优先进入包含此类型音频的文件夹',
            trailingText: 'wav > mp3 > flac > opus > m4a > aac',
          ),
          _Divider(),

          // 5. 默认播放列表 (UI 占位)
          DefaultPlaylistSettingTile(),
          _Divider(),

          // 6. 选择服务器 (★ 真实功能)
          _ServerSelectionTile(),
          _Divider(),
          // 8. 和谐标签 (UI 占位)
          _PlaceholderDropdownTile(
            icon: Icons.label,
            title: '和谐标签',
            subtitle: 'DLsite 和谐了一些标签（如 催眠-> 暗示），你可选择显示和谐 前/后 的标签',
            value: '不和谐 (默认)',
            items: ['不和谐 (默认)', '和谐', '双语显示'],
          ),
        ],
      ),
    );
  }
}

/// 1. 分割线组件
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 0.5, indent: 56, color: Theme.of(context).dividerColor.withOpacity(0.2));
  }
}

/// 2. 基础 Tile 样式封装
class _BaseSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _BaseSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
        children: [
          // 图标
          Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),

          // 文字区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500, // 标题加粗一点
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor, // 副标题灰色
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 尾部控件
          trailing,
        ],
      ),
    );
  }
}
/// 3. 服务器选择 Tile (功能实现)
class _ServerSelectionTile extends ConsumerWidget {
  const _ServerSelectionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 Provider 用于显示当前选中的值
    final currentServer = ref.watch(serverSettingsProvider);
    final theme = Theme.of(context);

    final displayLabel = EnvironmentConfig.getDisplayName(currentServer);

    return _BaseSettingTile(
      icon: Icons.dns_outlined,
      title: '选择服务器',
      subtitle: '点击测速并切换线路', // 稍微改一下文案，提示用户可以测速
      trailing: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // ★ 核心改变：点击弹出底部面板
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // 允许弹窗高度自适应
            builder: (context) => const ServerSelectionModal(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 显示当前选中的服务器名字
              Text(
                displayLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary, // 用主色调突出它是可点击的
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. 占位 Dropdown Tile (仅 UI)
class _PlaceholderDropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<String> items;

  const _PlaceholderDropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (v) {}, // 占位，不处理
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }
}

/// 5. 占位 Switch Tile (仅 UI)
class _PlaceholderSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  const _PlaceholderSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: (v) {}, // 占位，不处理
        // 模仿截图中的蓝色
      ),
    );
  }
}

/// 6. 静态文本 Tile (仅 UI，用于音频类型偏好)
class _StaticTextTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingText;

  const _StaticTextTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          trailingText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}