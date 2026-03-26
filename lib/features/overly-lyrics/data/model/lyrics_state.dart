// 定义字幕配置数据类
class LyricsState {
  // 悬浮窗是否显示
  final bool isShowing;
  final String text;
  final double fontSize;
  final double opacity;
  final bool isLocked;
  final bool isDraggable;

  const LyricsState({
    this.isShowing = false,
    this.text = '等待接收字幕...',
    this.fontSize = 24.0,
    this.opacity = 0.4,
    this.isLocked = false,
    this.isDraggable = true,
  });

  LyricsState copyWith({
    bool? isShowing,
    String? text,
    double? fontSize,
    double? opacity,
    bool? isLocked,
    bool? isDraggable,
  }) {
    return LyricsState(
      isShowing: isShowing ?? this.isShowing,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      isLocked: isLocked ?? this.isLocked,
      isDraggable: isDraggable ?? this.isDraggable,
    );
  }
}