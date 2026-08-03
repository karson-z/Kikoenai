import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 系统托盘服务。
///
/// 在桌面端启动时调用 [init] 创建托盘图标 + 右键菜单（显示 / 退出）。
/// 最小化到托盘时窗口被 [WindowCloseHandler] 隐藏，用户点击托盘菜单“显示”恢复。
class TrayService with TrayListener {
  TrayService._();
  static final TrayService instance = TrayService._();

  static const String _kMenuKeyShow = 'show';
  static const String _kMenuKeyExit = 'exit';

  bool _initialized = false;

  /// 初始化托盘。仅 Windows / macOS / Linux 桌面端生效。
  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    if (_initialized) return;

    try {
      trayManager.addListener(this);
      // 优先使用 Windows runner 自带的 app_icon.ico；打包后该路径仍可用。
      String iconPath;
      if (defaultTargetPlatform == TargetPlatform.windows) {
        iconPath = 'assets/icons/app_icon.ico';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        iconPath = 'assets/icons/app_icon.png';
      } else {
        iconPath = 'assets/icons/app_icon.png';
      }
      // 若指定资源不存在，退回到 Flutter 默认图标占位，避免抛异常。
      if (!await File(iconPath).exists()) {
        iconPath = defaultTargetPlatform == TargetPlatform.windows
            ? 'windows/runner/resources/app_icon.ico'
            : 'assets/images/app_show.png';
      }

      await trayManager.setIcon(iconPath);
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        await trayManager.setToolTip('Kikoenai');
      }

      final menu = Menu(
        items: [
          MenuItem(key: _kMenuKeyShow, label: '显示主窗口'),
          MenuItem.separator(),
          MenuItem(key: _kMenuKeyExit, label: '退出'),
        ],
      );
      await trayManager.setContextMenu(menu);
      _initialized = true;
    } catch (e) {
      debugPrint('TrayService init failed: $e');
    }
  }

  /// 托盘菜单点击。
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case _kMenuKeyShow:
        _restoreWindow();
        break;
      case _kMenuKeyExit:
        _exitApp();
        break;
    }
  }

  /// 双击托盘图标恢复窗口。
  @override
  void onTrayIconDoubleClick() {
    _restoreWindow();
  }

  /// 单击托盘图标也恢复窗口（Windows 习惯）。
  @override
  void onTrayIconMouseDown() {
    _restoreWindow();
  }

  Future<void> _restoreWindow() async {
    await windowManager.show();
    await windowManager.focus();
    // 恢复后把窗口从任务栏“最小化”状态抬到前台
    await windowManager.setSkipTaskbar(false);
  }

  Future<void> _exitApp() async {
    await trayManager.destroy();
    await windowManager.destroy();
  }

  /// 销毁托盘图标（应用退出前调用）。
  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      await trayManager.destroy();
      trayManager.removeListener(this);
    } catch (_) {}
    _initialized = false;
  }
}
