import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../storage/hive_key.dart';
import '../../storage/hive_storage.dart';
import 'tray_service.dart';

/// 窗口关闭动作。
enum WindowCloseAction {
  /// 最小化到系统托盘（保持后台运行）。
  minimize,

  /// 直接退出程序。
  exit,
}

/// 窗口关闭行为持久化值。null 表示尚未设置（每次询问）。
const _kMinimize = 'minimize';
const _kExit = 'exit';

WindowCloseAction? _readStored() {
  final v = AppStorage.settingsBox.get(StorageKeys.windowCloseBehavior);
  if (v == _kMinimize) return WindowCloseAction.minimize;
  if (v == _kExit) return WindowCloseAction.exit;
  return null;
}

Future<void> _writeStored(WindowCloseAction action) async {
  await AppStorage.settingsBox.put(
    StorageKeys.windowCloseBehavior,
    action == WindowCloseAction.minimize ? _kMinimize : _kExit,
  );
}

/// 统一的窗口关闭处理入口。
///
/// 行为：
/// - 若已记住选择，直接执行对应动作（最小化到托盘 / 退出）。
/// - 否则弹出对话框让用户选择，并提供“记住选择”勾选框。
///
/// 调用方：[WindowControlButtons] 的关闭按钮、以及 [WindowListener.onWindowClose]。
class WindowCloseHandler {
  WindowCloseHandler._();

  /// 处理关闭请求。返回 true 表示已退出（调用方一般无需关心返回值）。
  static Future<bool> handleClose(BuildContext? context) async {
    final stored = _readStored();
    if (stored != null) {
      await _execute(stored);
      return stored == WindowCloseAction.exit;
    }

    // 没有记住选择：弹窗询问（需要 context）
    if (context == null) {
      // 无上下文兜底：直接退出，避免无法关闭。
      await _execute(WindowCloseAction.exit);
      return true;
    }

    final action = await _showCloseDialog(context);
    if (action == null) return false; // 用户取消
    await _execute(action);
    return action == WindowCloseAction.exit;
  }

  /// 重置已记住的选择（设置页“重置关闭行为”可用）。
  static Future<void> resetRememberedChoice() async {
    await AppStorage.settingsBox.delete(StorageKeys.windowCloseBehavior);
  }

  static Future<void> _execute(WindowCloseAction action) async {
    switch (action) {
      case WindowCloseAction.minimize:
        // 隐藏窗口并从任务栏移除，仅保留托盘图标。
        await windowManager.setSkipTaskbar(true);
        await windowManager.hide();
      case WindowCloseAction.exit:
        await TrayService.instance.dispose();
        await windowManager.destroy();
    }
  }

  static Future<WindowCloseAction?> _showCloseDialog(BuildContext context) {
    bool remember = false;
    WindowCloseAction? selected;

    return showDialog<WindowCloseAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('关闭窗口'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('你希望如何关闭？'),
                  const SizedBox(height: 12),
                  _CloseOptionTile(
                    icon: Icons.minimize,
                    title: '最小化到托盘',
                    subtitle: '保持后台运行，可从系统托盘恢复',
                    selected: selected == WindowCloseAction.minimize,
                    onTap: () => setState(() {
                      selected = WindowCloseAction.minimize;
                    }),
                  ),
                  _CloseOptionTile(
                    icon: Icons.power_settings_new,
                    title: '退出程序',
                    subtitle: '完全退出应用',
                    selected: selected == WindowCloseAction.exit,
                    onTap: () => setState(() {
                      selected = WindowCloseAction.exit;
                    }),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: remember,
                    title: const Text('记住我的选择（不再询问）'),
                    onChanged: (v) => setState(() => remember = v ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          if (remember && selected != null) {
                            await _writeStored(selected!);
                          }
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop(selected);
                          }
                        },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CloseOptionTile extends StatelessWidget {
  const _CloseOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? color : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? color : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
