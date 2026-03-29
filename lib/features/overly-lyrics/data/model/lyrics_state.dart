import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lyrics_state.freezed.dart';

@freezed
abstract class LyricsState with _$LyricsState {
  const factory LyricsState({
    // 用户是否开启了桌面字幕功能（开关状态）
    @Default(false) bool isDesktopModeEnabled,
    // 悬浮窗物理上是否正在显示
    @Default(false) bool isWindowVisible,

    @Default(24.0) double fontSize,
    @Default(false) bool isLocked,
    @Default(Axis.horizontal) Axis orientation,
    @Default(Color(0xFFFFFFFF)) Color textColor,
    @Default(Color(0xFF000000)) Color backgroundColor,
    @Default('等待接收字幕...') String text,
    @Default(false) bool isPlaying,
  }) = _LyricsState;
}