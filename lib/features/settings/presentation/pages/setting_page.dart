import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import '../../../../config/app_version_config.dart';
import '../../../../config/environment_config.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/widgets/common/back_button_interceptor.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import '../../../overly-lyrics/presentation/widget/overly_setting_panel.dart';
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
        title: const Text('设置', style: TextStyle(fontSize: 22)),
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
                },
              ),
              _ChevronTile(
                title: '存储空间',
                onTap: () {
                  context.push(AppRoutes.settingsCache);
                },
              ),
              _ChevronTile(
                title: '邮箱',
                trailingText: isLoggedIn
                    ? authState.value?.currentUser?.email
                    : null,
                onTap: () {
                  //TODO 等待实现邮箱绑定功能
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: '播放与内容',
            children: [
              const DefaultPlaylistSettingTile(),
              const _LocalMediaSyncSettingsTile(),
              const HiveSwitchTile(
                title: '忽略音频焦点',
                storageKey: StorageKeys.ignoreAudioFocus,
                defaultValue: false,
              ),
              if (Platform.isAndroid)
                HiveSegmentedButtonTile<String>(
                  title: '音频输出引擎 (Android)',
                  subtitle: '如遇破音或无声请尝试切换，AAudio 延迟更低',
                  storageKey: StorageKeys.audioOutputMode, // 别忘了在 HiveKey 里补上这个
                  defaultValue: AppConstants.defaultAoMode,
                  options: const {
                    AppConstants.aoAudioTrack: 'AudioTrack',
                    AppConstants.aoAAudio: 'AAudio',
                    AppConstants.aoOpenSLES: 'OpenSL',
                  },
                ),
              _ChevronTile(
                title: '桌面字幕',
                trailingText: '配置桌面字幕',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) {
                      return const BackButtonPriorityWrapper(
                        zIndex: 101, // 确保层级高于之前的面板
                        name: 'SubtitleConfigBottomSheet',
                        child: SubtitleConfigBottomSheet(),
                      );
                    },
                  );
                },
              ),
              _ChevronTile(
                title: '音频类型偏好',
                trailingText: 'wav > mp3...',
                onTap: () {
                  // TODO: 弹出选择逻辑
                },
              ),
              const HiveSwitchTile(
                title: '是否NSFW',
                storageKey: StorageKeys.nsfwKey,
                defaultValue: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: '背景处理与性能',
            children: [
              HiveSliderTile(
                title: '模糊半径 (Blur Radius)',
                storageKey: StorageKeys.blurBackground,
                defaultValue: 10,
                min: 0,
                max: 50,
                divisions: 50,
              ),
              HiveSliderTile(
                title: '缩放分辨率 (Resize Width)',
                storageKey: StorageKeys.backgroundScale,
                defaultValue: 100,
                min: 10,
                max: 500,
                divisions: 49,
              ),
              HiveSliderTile(
                title: '编码质量 (JPEG Quality)',
                storageKey: StorageKeys.backgroundQuality,
                defaultValue: 70,
                min: 10,
                max: 100,
                divisions: 90,
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
                  context.push(AppRoutes.settingsGlobalFilter);
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
              _ChevronTile(
                title: '系统日志',
                onTap: () => context.push(AppRoutes.settingsLog),
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
  Widget _buildLogoutButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
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
          style: TextStyle(fontSize: 16, color: theme.colorScheme.error),
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
          style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
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
            child: Column(children: children),
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

  const _ChevronTile({required this.title, this.trailingText, this.onTap});

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

class _LocalMediaSyncSettingsTile extends StatefulWidget {
  const _LocalMediaSyncSettingsTile();

  @override
  State<_LocalMediaSyncSettingsTile> createState() =>
      _LocalMediaSyncSettingsTileState();
}

class _LocalMediaSyncSettingsTileState
    extends State<_LocalMediaSyncSettingsTile> {
  Box<dynamic> get _settingBox => AppStorage.settingsBox;

  bool get _enabled =>
      _settingBox.get(StorageKeys.localMediaAutoSyncEnabled, defaultValue: true)
          as bool;

  int get _thresholdHours =>
      _settingBox.get(
            StorageKeys.localMediaAutoSyncThresholdHours,
            defaultValue: 24,
          )
          as int;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: _settingBox.listenable(
        keys: [
          StorageKeys.localMediaAutoSyncEnabled,
          StorageKeys.localMediaAutoSyncThresholdHours,
        ],
      ),
      builder: (context, box, child) {
        final enabled = _enabled;
        final thresholdHours = _thresholdHours.clamp(1, 168);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本地媒体自动同步',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '进入媒体库时先显示缓存，超过阈值后后台同步磁盘',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (value) async {
                      await _settingBox.put(
                        StorageKeys.localMediaAutoSyncEnabled,
                        value,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '同步阈值',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.disabledColor,
                      ),
                    ),
                  ),
                  Text(
                    '$thresholdHours 小时',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: thresholdHours.toDouble(),
                min: 1,
                max: 168,
                divisions: 167,
                onChanged: enabled
                    ? (value) {
                        setState(() {
                          _settingBox.put(
                            StorageKeys.localMediaAutoSyncThresholdHours,
                            value.round(),
                          );
                        });
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class HiveSliderTile extends StatefulWidget {
  final String title;
  final String storageKey;
  final int defaultValue;
  final double min;
  final double max;
  final int divisions;

  const HiveSliderTile({
    super.key,
    required this.title,
    required this.storageKey,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.divisions,
  });

  @override
  State<HiveSliderTile> createState() => _HiveSliderTileState();
}

class _HiveSliderTileState extends State<HiveSliderTile> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    final rawValue = AppStorage.settingsBox.get(
      widget.storageKey,
      defaultValue: widget.defaultValue,
    );
    _currentValue = (rawValue as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              Text(
                _currentValue.toInt().toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _currentValue,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: (val) {
                setState(() {
                  _currentValue = val;
                });
              },
              onChangeEnd: (val) {
                AppStorage.settingsBox.put(widget.storageKey, val.toInt());
              },
            ),
          ),
        ],
      ),
    );
  }
}
