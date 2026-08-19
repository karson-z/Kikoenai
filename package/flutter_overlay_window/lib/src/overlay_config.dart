/// 悬浮窗在屏幕中的对齐位置。
enum OverlayAlignment {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

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

enum OverlayFlag {
  /// 窗口标志：该窗口永远不会接收触摸事件。
  /// 适用于需要展示点击穿透悬浮窗的场景。
  @Deprecated('Use "clickThrough" instead.')
  flagNotTouchable,

  /// 窗口标志：该窗口永远不会获取按键输入焦点，
  /// 因此用户无法向其发送按键或其他按钮事件。
  @Deprecated('Use "defaultFlag" instead.')
  flagNotFocusable,

  /// 窗口标志：允许窗口外部的指针事件传递到其后方的窗口。
  /// 适用于需要弹出键盘的输入框场景。
  @Deprecated('Use "focusPointer" instead.')
  flagNotTouchModal,

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

/// 锁屏界面上通知内容的可见级别。
enum NotificationVisibility {
  /// 在所有锁屏界面完整显示此通知。
  visibilityPublic,

  /// 在安全锁屏界面不显示此通知的任何内容。
  visibilitySecret,

  /// 在所有锁屏界面显示此通知，但在安全锁屏界面隐藏敏感或私密信息。
  visibilityPrivate,
}

class WindowSize {
  WindowSize._();

  /// 使悬浮窗尺寸与父容器一致。
  /// 即占满屏幕的宽度和高度。
  static const int matchParent = -1;

  /// 让悬浮窗覆盖整个屏幕，
  /// 包括状态栏和导航栏。
  static const int fullCover = -1999;
}
