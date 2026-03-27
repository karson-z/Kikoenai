import 'dart:io';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
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

  // 统一的事件暴露接口
  Stream<Map<String, dynamic>> get eventStream;

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

  // 同步业务状态 (包含歌词文本、播放状态等)
  Future<void> syncBusinessState(Map<String, dynamic> state);

  // 发送业务控制指令
  Future<void> sendCommand(String command, [dynamic payload]);

  // 释放资源
  void dispose();
}

class AndroidSubtitleManager implements SubtitleManager {
  // 1. 实现绝对单例模式
  static final AndroidSubtitleManager _instance = AndroidSubtitleManager._internal();
  factory AndroidSubtitleManager() => _instance;

  AndroidSubtitleManager._internal(); // 私有构造函数

  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();

  bool _isInitialized = false;
  StreamSubscription? _overlaySubscription; // 保存底层监听器的引用

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    // 2. 挂载系统级的消息通道，并保存引用
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((event) {
      debugPrint('IPC Receiver (Main): $event');
      if (event is Map) {
        final action = event['action'] as String?;
        final payload = event['payload'];

        if (action == 'UPDATE_POSITION') {
          _eventController.add({
            'action': 'UPDATE_POSITION',
            'payload': Offset(
              (event['dx'] as num?)?.toDouble() ?? 0.0,
              (event['dy'] as num?)?.toDouble() ?? 0.0,
            ),
          });
        } else if (action != null) {
          _eventController.add({
            'action': action,
            'payload': payload,
          });
        }
      }
    });
  }

  @override
  Future<void> showOverlay() async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true, // 开启原生拖拽，方便寻找和移动悬浮窗
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.center, // 避开底部计算的系统Bug，强制居中
      visibility: NotificationVisibility.visibilityPublic,
      width: -1,
      height: 350,
    );
  }

  @override
  Future<void> hideOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> lock() async {
    await FlutterOverlayWindow.updateFlag(OverlayFlag.clickThrough);
    await FlutterOverlayWindow.shareData({
      'action': 'LOCK_OVERLAY',
    });
  }

  @override
  Future<void> unlock() async {
    await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    await FlutterOverlayWindow.shareData({
      'action': 'UNLOCK_OVERLAY',
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

  @override
  Future<void> syncBusinessState(Map<String, dynamic> state) async {
    await FlutterOverlayWindow.shareData({
      'action': 'SYNC_BUSINESS_STATE',
      'payload': state,
    });
  }

  @override
  Future<void> sendCommand(String command, [dynamic payload]) async {
    try {
      debugPrint('IPC Sender (Overlay): $command');
      await FlutterOverlayWindow.shareData({
        'action': command,
        'payload': payload,
      });
    } catch (e) {
      debugPrint('IPC Send Exception: $e');
    }
  }

  @override
  void dispose() {
    // 3. 作为全局单例，通常不需要频繁 close。
    // 但为了严谨，如果你一定要 dispose，必须同时取消掉底层系统通道的订阅
    _overlaySubscription?.cancel();
    _isInitialized = false;
  }
}

class DesktopSubtitleManager extends WindowListener implements SubtitleManager {
  static final DesktopSubtitleManager _instance = DesktopSubtitleManager._internal();
  factory DesktopSubtitleManager() => _instance;

  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();

  DesktopSubtitleManager._internal() {
    windowManager.addListener(this);
  }

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // 桌面端窗口移动事件回调
  @override
  void onWindowMoved() async {
    final position = await windowManager.getPosition();
    _eventController.add({
      'action': 'UPDATE_POSITION',
      'payload': position,
    });
  }

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
    _eventController.add({'action': 'LOCK_OVERLAY'});
  }

  @override
  Future<void> unlock() async {
    await windowManager.setIgnoreMouseEvents(false);
    _eventController.add({'action': 'UNLOCK_OVERLAY'});
  }

  @override
  Future<void> setFontSize(double size) async {
    _eventController.add({
      'action': 'SET_FONT_SIZE',
      'payload': size,
    });
  }

  @override
  Future<void> setBackgroundOpacity(double opacity) async {
    _eventController.add({
      'action': 'SET_OPACITY',
      'payload': opacity,
    });
  }

  @override
  Future<void> setLayoutOrientation(Axis orientation) async {
    _eventController.add({
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
    _eventController.add({
      'action': 'SET_DRAGGABLE',
      'payload': isDraggable,
    });
  }

  @override
  Future<void> syncBusinessState(Map<String, dynamic> state) async {
    _eventController.add({
      'action': 'SYNC_BUSINESS_STATE',
      'payload': state,
    });
  }

  @override
  Future<void> sendCommand(String command, [dynamic payload]) async {
    _eventController.add({
      'action': command,
      'payload': payload,
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _eventController.close();
  }
}