import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kikoenai/core/theme/app_font_preset.dart';
import 'package:kikoenai/features/overly-lyrics/presentation/provider/overly_lyrics_provider.dart';
// TODO: 确保你的路径正确
import '../../../../core/theme/theme_view_model.dart';

class ThemeSettingPage extends ConsumerStatefulWidget {
  const ThemeSettingPage({super.key});

  @override
  ConsumerState<ThemeSettingPage> createState() => _ThemeSettingPageState();
}

class _ThemeSettingPageState extends ConsumerState<ThemeSettingPage> {
  static const _colors = <Color>[
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
  ];

  static const List<ThemeMode> _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  static const String _fontPreviewText = '字体预览 Font Preview 你好，世界';

  @override
  Widget build(BuildContext context) {
    // 获取当前的主题状态和方法
    final themeNotifier = ref.watch(themeNotifierProvider.notifier);
    final themeState = ref.watch(themeNotifierProvider);

    // 计算当前选中的主题模式索引
    final selectedModeIndex = _themeModes.indexOf(themeState.mode);
    final isSelected = List<bool>.generate(
      _themeModes.length,
      (i) => i == selectedModeIndex,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置', style: TextStyle(fontSize: 22)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ==============================
          // 还原你的原版：主题模式 (ToggleButtons)
          // ==============================
          const SizedBox(height: 8),
          const Text(
            '主题模式',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ToggleButtons(
              isSelected: isSelected,
              onPressed: (int index) {
                themeNotifier.setMode(_themeModes[index]);
              },
              borderRadius: BorderRadius.circular(10),
              constraints: const BoxConstraints.tightFor(width: 80, height: 45),
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_suggest, size: 18),
                    SizedBox(width: 4),
                    Text('系统', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.light_mode, size: 18),
                    SizedBox(width: 4),
                    Text('浅色', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dark_mode, size: 18),
                    SizedBox(width: 4),
                    Text('深色', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ==============================
          // 优化后的：主题色选择
          // ==============================
          _SettingsSection(
            title: '主题色',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // 遍历预设颜色
                    ..._colors.map((c) {
                      final isSelectedColor =
                          themeState.seedColor.toARGB32() == c.toARGB32();
                      return _ColorSwatch(
                        color: c,
                        isSelected: isSelectedColor,
                        onTap: () => themeNotifier.setSeedColor(c),
                      );
                    }),

                    // 自定义颜色按钮 (取色器)
                    _CustomColorButton(
                      currentColor: themeState.seedColor,
                      onTap: () => _showColorPicker(
                        context,
                        themeState.seedColor,
                        themeNotifier,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: '全局字体',
            children: AppFontPreset.values.map((preset) {
              final previewStyle = preset.applyToTextStyle(
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.35),
              );
              return _FontPresetTile(
                title: preset.label,
                subtitle: preset.description,
                preview: _fontPreviewText,
                previewStyle: previewStyle,
                isSelected: themeState.fontPreset == preset,
                onTap: () {
                  themeNotifier.setFontPreset(preset);
                  ref
                      .read(lyricsControllerProvider.notifier)
                      .updateFontPreset(preset);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 弹出自定义颜色选择器
  Future<void> _showColorPicker(
    BuildContext context,
    Color currentColor,
    dynamic themeState,
  ) async {
    Color tempColor = currentColor;
    Color originalColor = currentColor;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择自定义颜色', style: TextStyle(fontSize: 18)),
        contentPadding: const EdgeInsets.only(top: 20, bottom: 8),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              enableAlpha: false,
              displayThumbColor: true,
              hexInputBar: true,
              pickerAreaHeightPercent: 0.7,
              onColorChanged: (c) {
                setState(() => tempColor = c);
                themeState.setSeedColor(c, preview: true);
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              themeState.setSeedColor(originalColor, preview: true);
              Navigator.pop(ctx);
            },
            child: Text(
              '取消',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              themeState.setSeedColor(tempColor);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _FontPresetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String preview;
  final TextStyle? previewStyle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontPresetTile({
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.previewStyle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(preview, style: previewStyle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================
// UI 私有组件封装
// ========================================================

/// 1. 设置分组卡片容器
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// 2. 单个颜色圆块
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // 如果被选中，增加边框和阴影凸显
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white, // 颜色块内部的对勾用白色
                size: 20,
              )
            : null,
      ),
    );
  }
}

/// 3. 自定义颜色添加按钮
class _CustomColorButton extends StatelessWidget {
  final Color currentColor;
  final VoidCallback onTap;

  const _CustomColorButton({required this.currentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.colorize, // 吸管图标
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
