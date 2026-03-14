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