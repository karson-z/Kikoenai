// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lyrics_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LyricsState {

 bool get isDesktopModeEnabled; bool get isWindowVisible; double get fontSize; bool get isLocked; Axis get orientation; Color get textColor; Color get backgroundColor; String get text; bool get isPlaying;
/// Create a copy of LyricsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricsStateCopyWith<LyricsState> get copyWith => _$LyricsStateCopyWithImpl<LyricsState>(this as LyricsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricsState&&(identical(other.isDesktopModeEnabled, isDesktopModeEnabled) || other.isDesktopModeEnabled == isDesktopModeEnabled)&&(identical(other.isWindowVisible, isWindowVisible) || other.isWindowVisible == isWindowVisible)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.text, text) || other.text == text)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying));
}


@override
int get hashCode => Object.hash(runtimeType,isDesktopModeEnabled,isWindowVisible,fontSize,isLocked,orientation,textColor,backgroundColor,text,isPlaying);

@override
String toString() {
  return 'LyricsState(isDesktopModeEnabled: $isDesktopModeEnabled, isWindowVisible: $isWindowVisible, fontSize: $fontSize, isLocked: $isLocked, orientation: $orientation, textColor: $textColor, backgroundColor: $backgroundColor, text: $text, isPlaying: $isPlaying)';
}


}

/// @nodoc
abstract mixin class $LyricsStateCopyWith<$Res>  {
  factory $LyricsStateCopyWith(LyricsState value, $Res Function(LyricsState) _then) = _$LyricsStateCopyWithImpl;
@useResult
$Res call({
 bool isDesktopModeEnabled, bool isWindowVisible, double fontSize, bool isLocked, Axis orientation, Color textColor, Color backgroundColor, String text, bool isPlaying
});




}
/// @nodoc
class _$LyricsStateCopyWithImpl<$Res>
    implements $LyricsStateCopyWith<$Res> {
  _$LyricsStateCopyWithImpl(this._self, this._then);

  final LyricsState _self;
  final $Res Function(LyricsState) _then;

/// Create a copy of LyricsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isDesktopModeEnabled = null,Object? isWindowVisible = null,Object? fontSize = null,Object? isLocked = null,Object? orientation = null,Object? textColor = null,Object? backgroundColor = null,Object? text = null,Object? isPlaying = null,}) {
  return _then(_self.copyWith(
isDesktopModeEnabled: null == isDesktopModeEnabled ? _self.isDesktopModeEnabled : isDesktopModeEnabled // ignore: cast_nullable_to_non_nullable
as bool,isWindowVisible: null == isWindowVisible ? _self.isWindowVisible : isWindowVisible // ignore: cast_nullable_to_non_nullable
as bool,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Axis,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as Color,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricsState].
extension LyricsStatePatterns on LyricsState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricsState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricsState value)  $default,){
final _that = this;
switch (_that) {
case _LyricsState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricsState value)?  $default,){
final _that = this;
switch (_that) {
case _LyricsState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isDesktopModeEnabled,  bool isWindowVisible,  double fontSize,  bool isLocked,  Axis orientation,  Color textColor,  Color backgroundColor,  String text,  bool isPlaying)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricsState() when $default != null:
return $default(_that.isDesktopModeEnabled,_that.isWindowVisible,_that.fontSize,_that.isLocked,_that.orientation,_that.textColor,_that.backgroundColor,_that.text,_that.isPlaying);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isDesktopModeEnabled,  bool isWindowVisible,  double fontSize,  bool isLocked,  Axis orientation,  Color textColor,  Color backgroundColor,  String text,  bool isPlaying)  $default,) {final _that = this;
switch (_that) {
case _LyricsState():
return $default(_that.isDesktopModeEnabled,_that.isWindowVisible,_that.fontSize,_that.isLocked,_that.orientation,_that.textColor,_that.backgroundColor,_that.text,_that.isPlaying);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isDesktopModeEnabled,  bool isWindowVisible,  double fontSize,  bool isLocked,  Axis orientation,  Color textColor,  Color backgroundColor,  String text,  bool isPlaying)?  $default,) {final _that = this;
switch (_that) {
case _LyricsState() when $default != null:
return $default(_that.isDesktopModeEnabled,_that.isWindowVisible,_that.fontSize,_that.isLocked,_that.orientation,_that.textColor,_that.backgroundColor,_that.text,_that.isPlaying);case _:
  return null;

}
}

}

/// @nodoc


class _LyricsState implements LyricsState {
  const _LyricsState({this.isDesktopModeEnabled = false, this.isWindowVisible = false, this.fontSize = 24.0, this.isLocked = false, this.orientation = Axis.horizontal, this.textColor = const Color(0xFFFFFFFF), this.backgroundColor = const Color(0xFF000000), this.text = '等待接收字幕...', this.isPlaying = false});
  

@override@JsonKey() final  bool isDesktopModeEnabled;
@override@JsonKey() final  bool isWindowVisible;
@override@JsonKey() final  double fontSize;
@override@JsonKey() final  bool isLocked;
@override@JsonKey() final  Axis orientation;
@override@JsonKey() final  Color textColor;
@override@JsonKey() final  Color backgroundColor;
@override@JsonKey() final  String text;
@override@JsonKey() final  bool isPlaying;

/// Create a copy of LyricsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricsStateCopyWith<_LyricsState> get copyWith => __$LyricsStateCopyWithImpl<_LyricsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricsState&&(identical(other.isDesktopModeEnabled, isDesktopModeEnabled) || other.isDesktopModeEnabled == isDesktopModeEnabled)&&(identical(other.isWindowVisible, isWindowVisible) || other.isWindowVisible == isWindowVisible)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.textColor, textColor) || other.textColor == textColor)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.text, text) || other.text == text)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying));
}


@override
int get hashCode => Object.hash(runtimeType,isDesktopModeEnabled,isWindowVisible,fontSize,isLocked,orientation,textColor,backgroundColor,text,isPlaying);

@override
String toString() {
  return 'LyricsState(isDesktopModeEnabled: $isDesktopModeEnabled, isWindowVisible: $isWindowVisible, fontSize: $fontSize, isLocked: $isLocked, orientation: $orientation, textColor: $textColor, backgroundColor: $backgroundColor, text: $text, isPlaying: $isPlaying)';
}


}

/// @nodoc
abstract mixin class _$LyricsStateCopyWith<$Res> implements $LyricsStateCopyWith<$Res> {
  factory _$LyricsStateCopyWith(_LyricsState value, $Res Function(_LyricsState) _then) = __$LyricsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isDesktopModeEnabled, bool isWindowVisible, double fontSize, bool isLocked, Axis orientation, Color textColor, Color backgroundColor, String text, bool isPlaying
});




}
/// @nodoc
class __$LyricsStateCopyWithImpl<$Res>
    implements _$LyricsStateCopyWith<$Res> {
  __$LyricsStateCopyWithImpl(this._self, this._then);

  final _LyricsState _self;
  final $Res Function(_LyricsState) _then;

/// Create a copy of LyricsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isDesktopModeEnabled = null,Object? isWindowVisible = null,Object? fontSize = null,Object? isLocked = null,Object? orientation = null,Object? textColor = null,Object? backgroundColor = null,Object? text = null,Object? isPlaying = null,}) {
  return _then(_LyricsState(
isDesktopModeEnabled: null == isDesktopModeEnabled ? _self.isDesktopModeEnabled : isDesktopModeEnabled // ignore: cast_nullable_to_non_nullable
as bool,isWindowVisible: null == isWindowVisible ? _self.isWindowVisible : isWindowVisible // ignore: cast_nullable_to_non_nullable
as bool,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,orientation: null == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as Axis,textColor: null == textColor ? _self.textColor : textColor // ignore: cast_nullable_to_non_nullable
as Color,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
