import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import 'package:kikoenai/core/service/player/player_service.dart';
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
      // 优先使用打包进 assets 的图标；失败时退回 runner 自带资源。
      String iconPath;
      if (defaultTargetPlatform == TargetPlatform.windows) {
        iconPath = Assets.icons.appIcon;
      } else {
        // 历史遗留：assets/icons/app_icon.png 并不存在，非 Windows 直接用应用展示图。
        iconPath = Assets.images.appShow.path;
      }
      // 若指定资源不存在，退回到 Windows runner 自带的 app_icon.ico / 应用展示图，避免抛异常。
      if (!await File(iconPath).exists()) {
        iconPath = defaultTargetPlatform == TargetPlatform.windows
            ? 'windows/runner/resources/app_icon.ico'
            : Assets.images.appShow.path;
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
        exitApp();
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

  /// 干净退出应用（托盘菜单“退出”与关闭窗口的退出分支共用）。
  ///
  /// 顺序很关键：先隐藏窗口，让用户感知为“点击即关闭”；再释放最重的
  /// 原生资源——media_kit 的 mpv Player（不主动释放会导致进程退出卡顿
  /// 数秒，见 media-kit issue #180 / #266）与托盘图标；最后结束进程。
  /// 注意：window_manager 的 [windowManager.destroy] 在 Windows 上只是
  /// `PostQuitMessage(0)`，窗口要等整个引擎/插件拆完才消失，所以必须
  /// 先 [windowManager.hide]。
  Future<void> exitApp() async {
    try {
      await windowManager.hide();
    } catch (_) {
      // 窗口可能已销毁，忽略即可，不阻塞退出。
    }
    try {
      await PlayerService.instance.dispose();
    } catch (e) {
      debugPrint('PlayerService dispose failed on exit: $e');
    }
    try {
      await trayManager.destroy();
      trayManager.removeListener(this);
    } catch (_) {}
    _initialized = false;
    try {
      await windowManager.destroy();
    } catch (_) {}
  }
}
