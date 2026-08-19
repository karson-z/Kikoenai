<p align="center">
  <img src="https://github.com/X-SLAYER/flutter_overlay_window/assets/22800380/d22ae453-e83d-4da6-ba68-f4eaef666ef1" height="170" alt="auto_route_logo">
</p>

<p align="center">
  <a href="https://img.shields.io/badge/License-MIT-green">
    <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  </a>
  <a href="https://github.com/X-SLAYER/flutter_overlay_window">
    <img src="https://img.shields.io/github/stars/X-SLAYER/flutter_overlay_window?style=flat&logo=github&colorB=green&label=stars" alt="stars">
  </a>
  <a href="https://pub.dev/packages/flutter_overlay_window">
    <img src="https://img.shields.io/pub/v/flutter_overlay_window.svg?label=pub&color=orange" alt="pub version">
  </a>
</p>

<p align="center">
  <a href="https://www.buymeacoffee.com/xslayer" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px">
  </a>
</p>

<p align="center">
Flutter plugin for displaying your Flutter app over other apps on the screen
</p>

---

## Preview

|                                                          TrueCaller overlay example                                                          |                                                        click-through overlay example                                                        |                                                         Messanger chat-head example                                                         |
| :------------------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------------: |
| <img src='https://user-images.githubusercontent.com/22800380/165636217-8957396b-dc54-4e6d-aa50-e8bfdb9383cf.gif' height='600' width='300' /> | <img src='https://user-images.githubusercontent.com/22800380/165636120-dcd9ee13-5fca-4f8a-a562-b2f53c0b5e24.gif' height='600' width='300'/> | <img src='https://user-images.githubusercontent.com/22800380/178730917-40f267bb-63a2-4ad3-ba69-f7c1285a1882.gif' height='600' width='300'/> |

## Installation

Add package to your pubspec:

```yaml
dependencies:
  flutter_overlay_window: any # or the latest version on Pub
```

### Android

You'll need to add the `SYSTEM_ALERT_WINDOW` permission and `OverlayService` to your Android Manifest.
Replace `explanation_for_special_use` with your custom explanation.

```XML
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <application>
        ...
        <service android:name="flutter.overlay.window.flutter_overlay_window.OverlayService" 
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="explanation_for_special_use"/>
        </service>
    </application>
```

### Entry point

Inside `main.dart` create an entry point for your Overlay widget;

```dart

// 悬浮窗入口
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(child: Text("My overlay"))
  ));
}

```

### USAGE

```dart
 /// 检查是否已授予悬浮窗权限
 final bool status = await FlutterOverlayWindow.isPermissionGranted();

 /// 请求悬浮窗权限
 /// 此方法会打开悬浮窗设置页面，并在授权成功后返回 `true`。
 final bool status = await FlutterOverlayWindow.requestPermission();

  /// 显示悬浮窗内容
  ///
  /// 可选参数：
  ///
  /// `height`：悬浮窗高度，默认为 [WindowSize.fullCover]
  ///
  /// `width`：悬浮窗宽度，默认为 [WindowSize.matchParent]
  ///
  /// `alignment`：悬浮窗在屏幕中的对齐位置，默认为 [OverlayAlignment.center]
  ///
  /// `visibility`：锁屏通知内容的可见级别，默认为 [NotificationVisibility.visibilitySecret]
  ///
  /// `flag`：悬浮窗标志，默认为 [OverlayFlag.defaultFlag]
  ///
  /// `overlayTitle`：通知标题，默认为 "overlay activated"
  ///
  /// `overlayContent`：通知内容
  ///
  /// `enableDrag`：是否允许在屏幕上拖动悬浮窗，默认为 `false`
  ///
  /// `positionGravity`：悬浮窗拖动后的吸附方式，默认为 [PositionGravity.none]
  ///
  /// `startPosition`：悬浮窗的初始位置，默认为 `null`
 await FlutterOverlayWindow.showOverlay();

 /// 关闭已打开的悬浮窗
 await FlutterOverlayWindow.closeOverlay();

 /// 主应用 -> 悬浮窗
 await FlutterOverlayWindow.sendToOverlay("Hello overlay");

 /// 悬浮窗 -> 主应用
 await FlutterOverlayWindow.sendToMain("Hello main app");

 /// 在悬浮窗中监听此消息流。
 FlutterOverlayWindow.messagesFromMain.listen((event) {
   log("Message from main app: $event");
 });

 /// 在主应用中监听此消息流。
 FlutterOverlayWindow.messagesFromOverlay.listen((event) {
   log("Message from overlay app: $event");
 });

 /// 需要使用弹出键盘的输入框时，请使用 [OverlayFlag.focusPointer]
 await FlutterOverlayWindow.showOverlay(flag: OverlayFlag.focusPointer);


 /// 在悬浮窗运行期间更新窗口标志
 await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);

 /// 更新悬浮窗在屏幕中的尺寸。正数尺寸使用 dp。
 /// `keepTop` 可在高度变化时保持当前顶部边缘位置不变。
 await FlutterOverlayWindow.resizeOverlay(
   80,
   120,
   true,
   keepTop: true,
 );

 /// 更新悬浮窗在屏幕中的位置
  ///
 /// `position`：悬浮窗的新位置
  ///
 /// 返回值：位置更新成功时返回 `true`
 await FlutterOverlayWindow.moveOverlay(OverlayPosition(0, 156))

 /// 获取悬浮窗的当前位置
  ///
 /// 返回值：悬浮窗的当前位置
 await FlutterOverlayWindow.getOverlayPosition()

```

```dart

enum OverlayFlag {
  /// 窗口标志：该窗口永远不会接收触摸事件。
  /// 适用于需要展示点击穿透悬浮窗的场景。
  clickThrough,

  /// 窗口标志：该窗口永远不会获取按键输入焦点，
  /// 因此用户无法向其发送按键或其他按钮事件。
  defaultFlag,

  /// 窗口标志：允许窗口外部的指针事件传递到其后方的窗口。
  /// 适用于需要弹出键盘的输入框场景。
  focusPointer,
}

```

```dart

  /// 悬浮窗拖动后的吸附方式。
  enum PositionGravity {
    /// `PositionGravity.none` 允许将悬浮窗放置在屏幕中的任意位置。
    none,

    /// `PositionGravity.right` 使悬浮窗吸附在屏幕右侧。
    right,

    /// `PositionGravity.left` 使悬浮窗吸附在屏幕左侧。
    left,

    /// `PositionGravity.auto` 根据悬浮窗当前位置自动吸附到屏幕左侧或右侧；
    /// 如果悬浮窗超出顶部或底部，则在松手后回到最近的垂直边界。
    auto,
  }


```
