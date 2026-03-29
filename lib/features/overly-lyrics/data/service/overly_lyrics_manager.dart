import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
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
  Future<void> showOverlay({bool isLocked = false, double width = -1, double height = 350});

  // 隐藏字幕悬浮窗
  Future<void> hideOverlay();

  // 调整悬浮窗尺寸
  Future<void> resizeOverlay(double width, double height);

  // 开启点击穿透，进入锁定状态
  Future<void> lock({bool isMain = false});

  // 恢复事件拦截，解除锁定状态
  Future<void> unlock({bool isMain = false});

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
  Future<void> showOverlay({bool isLocked = false, double width = -1, double height = 550}) async {
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    // 根据传入的锁定状态决定初始 Flag
    final flag = isLocked ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag;

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      flag: flag,
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilityPublic,
      width: width.toInt(),
      height: height.toInt(),
      positionGravity: PositionGravity.auto,
    );
  }

  @override
  Future<void> hideOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> resizeOverlay(double width, double height) async {
    // enableDrag 传 true 保持窗口的可拖拽属性
    await FlutterOverlayWindow.resizeOverlay(width.toInt(), height.toInt(), true);
  }

  @override
  Future<void> lock({bool isMain = false}) async {
    if (!isMain) {
      await FlutterOverlayWindow.updateFlag(OverlayFlag.clickThrough);
    } else {
      await FlutterOverlayWindow.shareData({
        'action': 'LOCK_OVERLAY',
      });
    }
  }

  @override
  Future<void> unlock({bool isMain = false}) async {
    if (!isMain) {
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    } else {
      await FlutterOverlayWindow.shareData({
        'action': 'UNLOCK_OVERLAY',
      });
    }
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
      debugPrint('IPC Sender (Overlay Isolate): 尝试发送指令 $command');

      // 1. 查找主应用注册的播控端口
      final SendPort? sendPort = IsolateNameServer.lookupPortByName('overlay_playback_port');

      if (sendPort != null) {
        // 2. 找到端口，直接在内存中发送 String 指令
        sendPort.send(command);
        debugPrint('IPC Sender: 播控指令 [$command] 内存投递成功');
      } else {
        // 3. 找不到端口时，说明主应用引擎已被系统回收或端口未注册成功
        debugPrint('IPC Sender: ⚠️ 投递失败，未找到主应用的播控端口 overlay_playback_port');
      }
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
  Future<void> showOverlay({bool isLocked = false, double width = -1, double height = 350}) async {
    await windowManager.setSize(Size(width, height));
    await windowManager.setIgnoreMouseEvents(isLocked);
    await windowManager.show();
  }

  @override
  Future<void> hideOverlay() async {
    await windowManager.hide();
  }

  @override
  Future<void> resizeOverlay(double width, double height) async {
    // 如果传入的 width 是 matchParent (-1)，桌面端需要特殊处理或者给个固定默认值
    final w = width < 0 ? 800.0 : width;
    await windowManager.setSize(Size(w, height));
  }

  @override
  Future<void> lock({bool isMain = false}) async {
    await windowManager.setIgnoreMouseEvents(true);
    _eventController.add({'action': 'LOCK_OVERLAY'});
  }

  @override
  Future<void> unlock({bool isMain = false}) async {
    await windowManager.setIgnoreMouseEvents(false);
    _eventController.add({'action': 'UNLOCK_OVERLAY'});
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