import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

enum SubtitleEndpoint { main, overlay }

abstract class SubtitleManager {
  static const double defaultOverlayHeight = 190;

  factory SubtitleManager(SubtitleEndpoint endpoint) {
    if (Platform.isAndroid) {
      return AndroidSubtitleManager(endpoint);
    }
    return NoopSubtitleManager(endpoint);
  }

  SubtitleEndpoint get endpoint;

  /// Main -> Overlay messages. Only the overlay endpoint receives this stream.
  Stream<Map<String, dynamic>> get messagesFromMain;

  /// Overlay -> Main messages. Only the main endpoint receives this stream.
  Stream<Map<String, dynamic>> get messagesFromOverlay;

  Future<void> init();

  Future<void> showOverlay({
    bool isLocked = false,
    double width = -1,
    double height = SubtitleManager.defaultOverlayHeight,
    double posX = 0,
    double posY = 0,
  });

  Future<void> hideOverlay();

  Future<void> resizeOverlay(double width, double height);

  /// Changes the interaction flag on the overlay window itself.
  Future<void> setOverlayInteractionLocked(bool isLocked);

  /// Main -> Overlay sender.
  Future<void> sendToOverlay(String action, [dynamic payload]);

  /// Overlay -> Main sender.
  Future<void> sendToMain(String action, [dynamic payload]);

  Future<Offset> getOverlayPosition();

  void dispose();
}

class AndroidSubtitleManager implements SubtitleManager {
  static final Map<SubtitleEndpoint, AndroidSubtitleManager> _instances = {};

  factory AndroidSubtitleManager(SubtitleEndpoint endpoint) {
    return _instances.putIfAbsent(
      endpoint,
      () => AndroidSubtitleManager._internal(endpoint),
    );
  }

  AndroidSubtitleManager._internal(this.endpoint);

  @override
  final SubtitleEndpoint endpoint;

  final StreamController<Map<String, dynamic>> _messagesFromMainController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messagesFromOverlayController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isInitialized = false;
  StreamSubscription<dynamic>? _incomingSubscription;

  @override
  Stream<Map<String, dynamic>> get messagesFromMain =>
      _messagesFromMainController.stream;

  @override
  Stream<Map<String, dynamic>> get messagesFromOverlay =>
      _messagesFromOverlayController.stream;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (endpoint == SubtitleEndpoint.main) {
      _incomingSubscription = FlutterOverlayWindow.messagesFromOverlay.listen(
        (event) => _addMessage(event, _messagesFromOverlayController),
      );
    } else {
      _incomingSubscription = FlutterOverlayWindow.messagesFromMain.listen(
        (event) => _addMessage(event, _messagesFromMainController),
      );
    }
  }

  void _addMessage(
    dynamic event,
    StreamController<Map<String, dynamic>> controller,
  ) {
    debugPrint('IPC Receiver (${endpoint.name}): $event');
    if (event is! Map) return;

    controller.add({
      'action': event['action'] as String?,
      'payload': event['payload'],
    });
  }

  @override
  Future<void> showOverlay({
    bool isLocked = false,
    double width = -1,
    double height = SubtitleManager.defaultOverlayHeight,
    double posX = 0,
    double posY = 0,
  }) async {
    final isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    final flag = isLocked ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag;
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      flag: flag,
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilityPublic,
      width: width.toInt(),
      height: height.toInt(),
      positionGravity: PositionGravity.auto,
      startPosition: OverlayPosition(posX, posY),
    );
  }

  @override
  Future<void> hideOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> resizeOverlay(double width, double height) async {
    await FlutterOverlayWindow.resizeOverlay(
      width.toInt(),
      height.toInt(),
      true,
      keepTop: true,
    );
  }

  @override
  Future<void> setOverlayInteractionLocked(bool isLocked) async {
    _requireEndpoint(SubtitleEndpoint.overlay, 'setOverlayInteractionLocked');
    await FlutterOverlayWindow.updateFlag(
      isLocked ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag,
    );
  }

  @override
  Future<void> sendToOverlay(String action, [dynamic payload]) async {
    _requireEndpoint(SubtitleEndpoint.main, 'sendToOverlay');
    debugPrint('IPC Sender (Main -> Overlay): $action');
    await FlutterOverlayWindow.sendToOverlay({
      'action': action,
      'payload': payload,
    });
  }

  @override
  Future<void> sendToMain(String action, [dynamic payload]) async {
    _requireEndpoint(SubtitleEndpoint.overlay, 'sendToMain');
    debugPrint('IPC Sender (Overlay -> Main): $action');
    await FlutterOverlayWindow.sendToMain({
      'action': action,
      'payload': payload,
    });
  }

  void _requireEndpoint(SubtitleEndpoint expected, String operation) {
    if (endpoint != expected) {
      throw StateError(
        '$operation requires the ${expected.name} endpoint, '
        'but this manager is ${endpoint.name}.',
      );
    }
  }

  @override
  Future<Offset> getOverlayPosition() async {
    try {
      final position = await FlutterOverlayWindow.getOverlayPosition();
      return Offset(position.x.toDouble(), position.y.toDouble());
    } catch (error) {
      debugPrint('IPC Exception: 获取Android悬浮窗坐标失败 $error');
      return Offset.zero;
    }
  }

  @override
  void dispose() {
    unawaited(_incomingSubscription?.cancel());
    _incomingSubscription = null;
    _isInitialized = false;
  }
}

/// Android 以外的平台不启用系统悬浮歌词，但保持调用链安全。
class NoopSubtitleManager implements SubtitleManager {
  static final Map<SubtitleEndpoint, NoopSubtitleManager> _instances = {};

  factory NoopSubtitleManager(SubtitleEndpoint endpoint) {
    return _instances.putIfAbsent(
      endpoint,
      () => NoopSubtitleManager._internal(endpoint),
    );
  }

  NoopSubtitleManager._internal(this.endpoint);

  @override
  final SubtitleEndpoint endpoint;

  final StreamController<Map<String, dynamic>> _messagesFromMainController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messagesFromOverlayController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messagesFromMain =>
      _messagesFromMainController.stream;

  @override
  Stream<Map<String, dynamic>> get messagesFromOverlay =>
      _messagesFromOverlayController.stream;

  @override
  Future<void> init() async {}

  @override
  Future<void> showOverlay({
    bool isLocked = false,
    double width = -1,
    double height = SubtitleManager.defaultOverlayHeight,
    double posX = 0,
    double posY = 0,
  }) async {}

  @override
  Future<void> hideOverlay() async {}

  @override
  Future<void> resizeOverlay(double width, double height) async {}

  @override
  Future<void> setOverlayInteractionLocked(bool isLocked) async {}

  @override
  Future<void> sendToOverlay(String action, [dynamic payload]) async {}

  @override
  Future<void> sendToMain(String action, [dynamic payload]) async {}

  @override
  Future<Offset> getOverlayPosition() async => Offset.zero;

  @override
  void dispose() {}
}
