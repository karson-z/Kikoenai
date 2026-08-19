import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/src/models/overlay_position.dart';
import 'package:flutter_overlay_window/src/overlay_config.dart';

class FlutterOverlayWindow {
  FlutterOverlayWindow._();

  static final StreamController _controller = StreamController();
  static final StreamController<dynamic> _messagesFromMainController =
      StreamController<dynamic>.broadcast();
  static final StreamController<dynamic> _messagesFromOverlayController =
      StreamController<dynamic>.broadcast();
  static const MethodChannel _channel = MethodChannel(
    "x-slayer/overlay_channel",
  );
  static const MethodChannel _overlayChannel = MethodChannel(
    "x-slayer/overlay",
  );
  static const BasicMessageChannel _overlayMessageChannel = BasicMessageChannel(
    "x-slayer/overlay_messenger",
    JSONMessageCodec(),
  );
  static const BasicMessageChannel<dynamic> _mainToOverlayMessageChannel =
      BasicMessageChannel<dynamic>(
        "x-slayer/overlay_messenger/main_to_overlay",
        JSONMessageCodec(),
      );
  static const BasicMessageChannel<dynamic> _overlayToMainMessageChannel =
      BasicMessageChannel<dynamic>(
        "x-slayer/overlay_messenger/overlay_to_main",
        JSONMessageCodec(),
      );

  /// 显示悬浮窗内容。
  ///
  /// 可选参数：
  ///
  /// `height`：悬浮窗高度，默认为 [WindowSize.fullCover]。
  ///
  /// `width`：悬浮窗宽度，默认为 [WindowSize.matchParent]。
  ///
  /// `alignment`：悬浮窗在屏幕中的对齐位置，默认为 [OverlayAlignment.center]。
  ///
  /// `visibility`：锁屏通知内容的可见级别，默认为 [NotificationVisibility.visibilitySecret]。
  ///
  /// `flag`：悬浮窗标志，默认为 [OverlayFlag.defaultFlag]。
  ///
  /// `overlayTitle`：通知标题，默认为 "overlay activated"。
  ///
  /// `overlayContent`：通知内容。
  ///
  /// `enableDrag`：是否允许在屏幕上拖动悬浮窗，默认为 `false`。
  ///
  /// `positionGravity`：悬浮窗拖动后的吸附方式，默认为 [PositionGravity.none]。
  ///
  /// `startPosition`：悬浮窗的初始位置，默认为 `null`。
  static Future<void> showOverlay({
    int height = WindowSize.fullCover,
    int width = WindowSize.matchParent,
    OverlayAlignment alignment = OverlayAlignment.center,
    NotificationVisibility visibility = NotificationVisibility.visibilitySecret,
    OverlayFlag flag = OverlayFlag.defaultFlag,
    String overlayTitle = "overlay activated",
    String? overlayContent,
    bool enableDrag = false,
    PositionGravity positionGravity = PositionGravity.none,
    OverlayPosition? startPosition,
  }) async {
    await _channel.invokeMethod('showOverlay', {
      "height": height,
      "width": width,
      "alignment": alignment.name,
      "flag": flag.name,
      "overlayTitle": overlayTitle,
      "overlayContent": overlayContent,
      "enableDrag": enableDrag,
      "notificationVisibility": visibility.name,
      "positionGravity": positionGravity.name,
      "startPosition": startPosition?.toMap(),
    });
  }

  /// 检查是否已授予悬浮窗权限。
  static Future<bool> isPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('checkPermission') ?? false;
    } on PlatformException catch (error) {
      log("$error");
      return Future.value(false);
    }
  }

  /// 请求悬浮窗权限。
  /// 此方法会打开悬浮窗设置页面，并在授权成功后返回 `true`。
  static Future<bool?> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool?>('requestPermission');
    } on PlatformException catch (error) {
      log("Error requestPermession: $error");
      rethrow;
    }
  }

  /// 关闭已打开的悬浮窗。
  static Future<bool?> closeOverlay() async {
    final bool? result = await _channel.invokeMethod('closeOverlay');
    return result;
  }

  /// 将数据从主应用发送到悬浮窗。
  static Future<dynamic> sendToOverlay(dynamic data) {
    return _mainToOverlayMessageChannel.send(data);
  }

  /// 由主应用发送、供悬浮窗接收的消息流。
  static Stream<dynamic> get messagesFromMain {
    _mainToOverlayMessageChannel.setMessageHandler((message) async {
      _messagesFromMainController.add(message);
      return message;
    });
    return _messagesFromMainController.stream;
  }

  /// 将数据从悬浮窗发送到主应用。
  static Future<dynamic> sendToMain(dynamic data) {
    return _overlayToMainMessageChannel.send(data);
  }

  /// 由悬浮窗发送、供主应用接收的消息流。
  static Stream<dynamic> get messagesFromOverlay {
    _overlayToMainMessageChannel.setMessageHandler((message) async {
      _messagesFromOverlayController.add(message);
      return message;
    });
    return _messagesFromOverlayController.stream;
  }

  /// 在主应用和悬浮窗之间双向传递数据。
  @Deprecated(
    'Use sendToOverlay from the main app or sendToMain from the overlay app.',
  )
  static Future shareData(dynamic data) async {
    return await _overlayMessageChannel.send(data);
  }

  /// 主应用与悬浮窗之间共享的消息流。
  @Deprecated(
    'Use messagesFromMain in the overlay app or messagesFromOverlay in the main app.',
  )
  static Stream<dynamic> get overlayListener {
    _overlayMessageChannel.setMessageHandler((message) async {
      _controller.add(message);
      return message;
    });
    return _controller.stream;
  }

  /// 在悬浮窗运行期间更新窗口标志。
  static Future<bool?> updateFlag(OverlayFlag flag) async {
    final bool? result = await _overlayChannel.invokeMethod<bool?>(
      'updateFlag',
      {'flag': flag.name},
    );
    return result;
  }

  /// 更新悬浮窗在屏幕中的尺寸。
  static Future<bool?> resizeOverlay(
    int width,
    int height,
    bool enableDrag, {
    bool keepTop = false,
  }) async {
    final bool? result = await _overlayChannel.invokeMethod<bool?>(
      'resizeOverlay',
      {
        'width': width,
        'height': height,
        'enableDrag': enableDrag,
        'keepTop': keepTop,
      },
    );
    return result;
  }

  /// 更新悬浮窗在屏幕中的位置。
  ///
  /// `position`：悬浮窗的新位置。
  ///
  /// 返回值：位置更新成功时返回 `true`。
  static Future<bool?> moveOverlay(OverlayPosition position) async {
    final bool? result = await _channel.invokeMethod<bool?>(
      'moveOverlay',
      position.toMap(),
    );
    return result;
  }

  /// 获取悬浮窗的当前位置。
  ///
  /// 返回值：悬浮窗的当前位置。
  static Future<OverlayPosition> getOverlayPosition() async {
    final Map<Object?, Object?>? result = await _channel.invokeMethod(
      'getOverlayPosition',
    );
    return OverlayPosition.fromMap(result);
  }

  /// 检查悬浮窗当前是否处于活动状态。
  static Future<bool> isActive() async {
    final bool? result = await _channel.invokeMethod<bool?>('isOverlayActive');
    return result ?? false;
  }

  /// 释放悬浮窗消息流。
  static void disposeOverlayListener() {
    _controller.close();
  }
}
