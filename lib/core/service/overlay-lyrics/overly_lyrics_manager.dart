import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

abstract class SubtitleManager {
  factory SubtitleManager() {
    if (Platform.isWindows || Platform.isLinux) {
      return DesktopSubtitleManager();
    } else if (Platform.isAndroid) {
      return AndroidSubtitleManager();
    }
    throw UnsupportedError('Unsupported platform');
  }

  // 初始化底层环境与权限
  Future<void> init();

  // 显示字幕悬浮窗
  Future<void> showOverlay();

  // 隐藏字幕悬浮窗
  Future<void> hideOverlay();

  // 开启点击穿透，进入锁定状态
  Future<void> lock();

  // 恢复事件拦截，解除锁定状态
  Future<void> unlock();

  // 下发字幕文本内容
  Future<void> updateText(String text);

  // 设置字幕字体大小
  Future<void> setFontSize(double size);

  // 设置悬浮窗背景/边框透明度 (0.0 为全透，1.0 为不透)
  Future<void> setBackgroundOpacity(double opacity);

  // 设置字幕排列方向 (Axis.horizontal 为水平，Axis.vertical 为垂直)
  Future<void> setLayoutOrientation(Axis orientation);

  // 调整悬浮窗物理尺寸
  Future<void> setWindowSize(double width, double height);

  // 设置是否允许拖拽
  Future<void> setDraggable(bool isDraggable);
}

class AndroidSubtitleManager implements SubtitleManager {
  @override
  Future<void> init() async {
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  @override
  Future<void> showOverlay() async {
    await FlutterOverlayWindow.showOverlay(
      // 禁用插件原生的拖拽，统一交由 UI 层的 GestureDetector 接管
      enableDrag: false,
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.bottomCenter,
      visibility: NotificationVisibility.visibilityPublic,
    );
  }

  @override
  Future<void> hideOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> lock() async {
    await FlutterOverlayWindow.shareData({
      'action': 'LOCK_OVERLAY',
    });
  }

  @override
  Future<void> unlock() async {
    await FlutterOverlayWindow.shareData({
      'action': 'UNLOCK_OVERLAY',
    });
  }

  @override
  Future<void> updateText(String text) async {
    await FlutterOverlayWindow.shareData({
      'action': 'UPDATE_TEXT',
      'payload': text,
    });
  }

  @override
  Future<void> setFontSize(double size) async {
    await FlutterOverlayWindow.shareData({
      'action': 'SET_FONT_SIZE',
      'payload': size,
    });
  }

  @override
  Future<void> setBackgroundOpacity(double opacity) async {
    await FlutterOverlayWindow.shareData({
      'action': 'SET_OPACITY',
      'payload': opacity,
    });
  }

  @override
  Future<void> setLayoutOrientation(Axis orientation) async {
    await FlutterOverlayWindow.shareData({
      'action': 'SET_ORIENTATION',
      'payload': orientation.index,
    });
  }

  @override
  Future<void> setWindowSize(double width, double height) async {
    await FlutterOverlayWindow.resizeOverlay(width.toInt(), height.toInt(), true);
  }

  @override
  Future<void> setDraggable(bool isDraggable) async {
    await FlutterOverlayWindow.shareData({
      'action': 'SET_DRAGGABLE',
      'payload': isDraggable,
    });
  }
}

class DesktopSubtitleManager implements SubtitleManager {
  static final DesktopSubtitleManager _instance = DesktopSubtitleManager._internal();
  factory DesktopSubtitleManager() => _instance;
  DesktopSubtitleManager._internal();

  final StreamController<Map<String, dynamic>> _uiEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get uiEventStream => _uiEventController.stream;

  @override
  Future<void> init() async {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 150),
      center: true,
      backgroundColor: Color(0x00000000),
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setHasShadow(false);
    });

    await trayManager.setIcon('assets/icons/tray_icon.ico');
  }

  @override
  Future<void> showOverlay() async {
    await windowManager.show();
  }

  @override
  Future<void> hideOverlay() async {
    await windowManager.hide();
  }

  @override
  Future<void> lock() async {
    await windowManager.setIgnoreMouseEvents(true);
    _uiEventController.add({'action': 'LOCK_OVERLAY'});
  }

  @override
  Future<void> unlock() async {
    await windowManager.setIgnoreMouseEvents(false);
    _uiEventController.add({'action': 'UNLOCK_OVERLAY'});
  }

  @override
  Future<void> updateText(String text) async {
    _uiEventController.add({
      'action': 'UPDATE_TEXT',
      'payload': text,
    });
  }

  @override
  Future<void> setFontSize(double size) async {
    _uiEventController.add({
      'action': 'SET_FONT_SIZE',
      'payload': size,
    });
  }

  @override
  Future<void> setBackgroundOpacity(double opacity) async {
    _uiEventController.add({
      'action': 'SET_OPACITY',
      'payload': opacity,
    });
  }

  @override
  Future<void> setLayoutOrientation(Axis orientation) async {
    _uiEventController.add({
      'action': 'SET_ORIENTATION',
      'payload': orientation.index,
    });
  }

  @override
  Future<void> setWindowSize(double width, double height) async {
    await windowManager.setSize(Size(width, height));
  }

  @override
  Future<void> setDraggable(bool isDraggable) async {
    _uiEventController.add({
      'action': 'SET_DRAGGABLE',
      'payload': isDraggable,
    });
  }

  void dispose() {
    _uiEventController.close();
  }
}