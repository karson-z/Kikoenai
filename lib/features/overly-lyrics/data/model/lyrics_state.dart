import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lyrics_state.freezed.dart';

@freezed
abstract class LyricsState with _$LyricsState {
  const factory LyricsState({
    @Default(false) bool isShowing,
    @Default(24.0) double fontSize,
    @Default(0.4) double opacity,
    @Default(false) bool isLocked,
    @Default(true) bool isDraggable,
    @Default(Axis.horizontal) Axis orientation,
    @Default(Size(-1, 350)) Size windowSize,
    @Default(Color(0xFFFFFFFF)) Color textColor,
    @Default(Color(0xFF000000)) Color backgroundColor,
    @Default(Offset.zero) Offset position,
    @Default('等待接收字幕...') String text,
    @Default(false) bool isPlaying,
  }) = _LyricsState;
}