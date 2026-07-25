import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';

import '../../../../core/storage/hive_storage.dart';

/// 5. 专门针对 Hive 存储的自动化开关 Tile
class HiveSwitchTile extends StatelessWidget {
  final String title;
  final String storageKey;
  final bool defaultValue;

  const HiveSwitchTile({
    super.key,
    required this.title,
    required this.storageKey,
    this.defaultValue = false,
  });

  @override
  Widget build(BuildContext context) {
    // 获取统一的 Box 实例
    final box = AppStorage.settingsBox;

    return ValueListenableBuilder(
      // 内部自动监听传入的 Key
      valueListenable: box.listenable(keys: [storageKey]),
      builder: (context, box, child) {
        final currentValue = box.get(storageKey, defaultValue: defaultValue) as bool;

        return _SwitchTile(
          title: title,
          value: currentValue,
          onChanged: (value) async {
            // 内部自动处理存储逻辑
            await box.put(storageKey, value);
          },
        );
      },
    );
  }
}
class HiveSegmentedButtonTile<T> extends StatelessWidget {
  final String title;
  final String storageKey;
  final T defaultValue;
  final Map<T, String> options; // Key 是实际存入 Hive 的值，Value 是 UI 上显示的文案
  final String? subtitle;

  const HiveSegmentedButtonTile({
    super.key,
    required this.title,
    required this.storageKey,
    required this.defaultValue,
    required this.options,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final box = AppStorage.settingsBox;
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: [storageKey]),
      builder: (context, box, child) {
        final currentValue = box.get(storageKey, defaultValue: defaultValue) as T;
        // 防御性编程：防止存储了被废弃的值
        final safeValue = options.containsKey(currentValue) ? currentValue : defaultValue;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<T>(
                  segments: options.entries.map((e) {
                    return ButtonSegment<T>(
                      value: e.key,
                      label: Text(e.value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  selected: {safeValue},
                  showSelectedIcon: false, // 隐藏打勾图标，让文案居中更美观
                  onSelectionChanged: (Set<T> newSelection) async {
                    await box.put(storageKey, newSelection.first);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/// 3. 带开关的设置项 (Switch)
class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged?.call(!value), // 点击整行也能切换
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Switch 本身有高度，vertical 稍微减小
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                // Switch 颜色会自动跟随你 App 的 theme.colorScheme.primary
              ),
            ],
          ),
        ),
      ),
    );
  }
}