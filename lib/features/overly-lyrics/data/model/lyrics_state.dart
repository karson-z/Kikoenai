import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lyrics_state.freezed.dart';


@freezed
abstract class LyricsState with _$LyricsState {
  const factory LyricsState({
    @Default(false) bool isDesktopModeEnabled,
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