// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppPlayerState {

@HiveField(0) bool get playing;@HiveField(1) bool get loading;@HiveField(2) ProgressBarState get progressBarState;@HiveField(5) bool get isFirst;@HiveField(6) bool get isLast;@HiveField(7) bool get shuffleEnabled;@HiveField(8) AudioServiceRepeatMode get repeatMode;@HiveField(9) double get volume;@HiveField(12) bool get isAudioOnly;@HiveField(13) PlaybackSession? get session; bool get isVideoControlsVisible; int get videoWidth; int get videoHeight; int get videoRotate; String get audioParams; AudioTrack? get audioTrack; SubtitleTrack? get subtitleTrack; List<AudioTrack> get availableAudioTracks; List<SubtitleTrack> get availableSubtitleTracks;// 外部挂载的轨道列??
 List<AudioTrack> get externalAudioTracks; List<SubtitleTrack> get externalSubtitleTracks;
/// Create a copy of AppPlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppPlayerStateCopyWith<AppPlayerState> get copyWith => _$AppPlayerStateCopyWithImpl<AppPlayerState>(this as AppPlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppPlayerState&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.progressBarState, progressBarState) || other.progressBarState == progressBarState)&&(identical(other.isFirst, isFirst) || other.isFirst == isFirst)&&(identical(other.isLast, isLast) || other.isLast == isLast)&&(identical(other.shuffleEnabled, shuffleEnabled) || other.shuffleEnabled == shuffleEnabled)&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.isAudioOnly, isAudioOnly) || other.isAudioOnly == isAudioOnly)&&(identical(other.session, session) || other.session == session)&&(identical(other.isVideoControlsVisible, isVideoControlsVisible) || other.isVideoControlsVisible == isVideoControlsVisible)&&(identical(other.videoWidth, videoWidth) || other.videoWidth == videoWidth)&&(identical(other.videoHeight, videoHeight) || other.videoHeight == videoHeight)&&(identical(other.videoRotate, videoRotate) || other.videoRotate == videoRotate)&&(identical(other.audioParams, audioParams) || other.audioParams == audioParams)&&(identical(other.audioTrack, audioTrack) || other.audioTrack == audioTrack)&&(identical(other.subtitleTrack, subtitleTrack) || other.subtitleTrack == subtitleTrack)&&const DeepCollectionEquality().equals(other.availableAudioTracks, availableAudioTracks)&&const DeepCollectionEquality().equals(other.availableSubtitleTracks, availableSubtitleTracks)&&const DeepCollectionEquality().equals(other.externalAudioTracks, externalAudioTracks)&&const DeepCollectionEquality().equals(other.externalSubtitleTracks, externalSubtitleTracks));
}


@override
int get hashCode => Object.hashAll([runtimeType,playing,loading,progressBarState,isFirst,isLast,shuffleEnabled,repeatMode,volume,isAudioOnly,session,isVideoControlsVisible,videoWidth,videoHeight,videoRotate,audioParams,audioTrack,subtitleTrack,const DeepCollectionEquality().hash(availableAudioTracks),const DeepCollectionEquality().hash(availableSubtitleTracks),const DeepCollectionEquality().hash(externalAudioTracks),const DeepCollectionEquality().hash(externalSubtitleTracks)]);

@override
String toString() {
  return 'AppPlayerState(playing: $playing, loading: $loading, progressBarState: $progressBarState, isFirst: $isFirst, isLast: $isLast, shuffleEnabled: $shuffleEnabled, repeatMode: $repeatMode, volume: $volume, isAudioOnly: $isAudioOnly, session: $session, isVideoControlsVisible: $isVideoControlsVisible, videoWidth: $videoWidth, videoHeight: $videoHeight, videoRotate: $videoRotate, audioParams: $audioParams, audioTrack: $audioTrack, subtitleTrack: $subtitleTrack, availableAudioTracks: $availableAudioTracks, availableSubtitleTracks: $availableSubtitleTracks, externalAudioTracks: $externalAudioTracks, externalSubtitleTracks: $externalSubtitleTracks)';
}


}

/// @nodoc
abstract mixin class $AppPlayerStateCopyWith<$Res>  {
  factory $AppPlayerStateCopyWith(AppPlayerState value, $Res Function(AppPlayerState) _then) = _$AppPlayerStateCopyWithImpl;
@useResult
$Res call({
@HiveField(0) bool playing,@HiveField(1) bool loading,@HiveField(2) ProgressBarState progressBarState,@HiveField(5) bool isFirst,@HiveField(6) bool isLast,@HiveField(7) bool shuffleEnabled,@HiveField(8) AudioServiceRepeatMode repeatMode,@HiveField(9) double volume,@HiveField(12) bool isAudioOnly,@HiveField(13) PlaybackSession? session, bool isVideoControlsVisible, int videoWidth, int videoHeight, int videoRotate, String audioParams, AudioTrack? audioTrack, SubtitleTrack? subtitleTrack, List<AudioTrack> availableAudioTracks, List<SubtitleTrack> availableSubtitleTracks, List<AudioTrack> externalAudioTracks, List<SubtitleTrack> externalSubtitleTracks
});


$PlaybackSessionCopyWith<$Res>? get session;

}
/// @nodoc
class _$AppPlayerStateCopyWithImpl<$Res>
    implements $AppPlayerStateCopyWith<$Res> {
  _$AppPlayerStateCopyWithImpl(this._self, this._then);

  final AppPlayerState _self;
  final $Res Function(AppPlayerState) _then;

/// Create a copy of AppPlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playing = null,Object? loading = null,Object? progressBarState = null,Object? isFirst = null,Object? isLast = null,Object? shuffleEnabled = null,Object? repeatMode = null,Object? volume = null,Object? isAudioOnly = null,Object? session = freezed,Object? isVideoControlsVisible = null,Object? videoWidth = null,Object? videoHeight = null,Object? videoRotate = null,Object? audioParams = null,Object? audioTrack = freezed,Object? subtitleTrack = freezed,Object? availableAudioTracks = null,Object? availableSubtitleTracks = null,Object? externalAudioTracks = null,Object? externalSubtitleTracks = null,}) {
  return _then(_self.copyWith(
playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,progressBarState: null == progressBarState ? _self.progressBarState : progressBarState // ignore: cast_nullable_to_non_nullable
as ProgressBarState,isFirst: null == isFirst ? _self.isFirst : isFirst // ignore: cast_nullable_to_non_nullable
as bool,isLast: null == isLast ? _self.isLast : isLast // ignore: cast_nullable_to_non_nullable
as bool,shuffleEnabled: null == shuffleEnabled ? _self.shuffleEnabled : shuffleEnabled // ignore: cast_nullable_to_non_nullable
as bool,repeatMode: null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as AudioServiceRepeatMode,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,isAudioOnly: null == isAudioOnly ? _self.isAudioOnly : isAudioOnly // ignore: cast_nullable_to_non_nullable
as bool,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as PlaybackSession?,isVideoControlsVisible: null == isVideoControlsVisible ? _self.isVideoControlsVisible : isVideoControlsVisible // ignore: cast_nullable_to_non_nullable
as bool,videoWidth: null == videoWidth ? _self.videoWidth : videoWidth // ignore: cast_nullable_to_non_nullable
as int,videoHeight: null == videoHeight ? _self.videoHeight : videoHeight // ignore: cast_nullable_to_non_nullable
as int,videoRotate: null == videoRotate ? _self.videoRotate : videoRotate // ignore: cast_nullable_to_non_nullable
as int,audioParams: null == audioParams ? _self.audioParams : audioParams // ignore: cast_nullable_to_non_nullable
as String,audioTrack: freezed == audioTrack ? _self.audioTrack : audioTrack // ignore: cast_nullable_to_non_nullable
as AudioTrack?,subtitleTrack: freezed == subtitleTrack ? _self.subtitleTrack : subtitleTrack // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,availableAudioTracks: null == availableAudioTracks ? _self.availableAudioTracks : availableAudioTracks // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,availableSubtitleTracks: null == availableSubtitleTracks ? _self.availableSubtitleTracks : availableSubtitleTracks // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,externalAudioTracks: null == externalAudioTracks ? _self.externalAudioTracks : externalAudioTracks // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,externalSubtitleTracks: null == externalSubtitleTracks ? _self.externalSubtitleTracks : externalSubtitleTracks // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,
  ));
}
/// Create a copy of AppPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $PlaybackSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppPlayerState].
extension AppPlayerStatePatterns on AppPlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppPlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppPlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppPlayerState value)  $default,){
final _that = this;
switch (_that) {
case _AppPlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppPlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _AppPlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  bool playing, @HiveField(1)  bool loading, @HiveField(2)  ProgressBarState progressBarState, @HiveField(5)  bool isFirst, @HiveField(6)  bool isLast, @HiveField(7)  bool shuffleEnabled, @HiveField(8)  AudioServiceRepeatMode repeatMode, @HiveField(9)  double volume, @HiveField(12)  bool isAudioOnly, @HiveField(13)  PlaybackSession? session,  bool isVideoControlsVisible,  int videoWidth,  int videoHeight,  int videoRotate,  String audioParams,  AudioTrack? audioTrack,  SubtitleTrack? subtitleTrack,  List<AudioTrack> availableAudioTracks,  List<SubtitleTrack> availableSubtitleTracks,  List<AudioTrack> externalAudioTracks,  List<SubtitleTrack> externalSubtitleTracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppPlayerState() when $default != null:
return $default(_that.playing,_that.loading,_that.progressBarState,_that.isFirst,_that.isLast,_that.shuffleEnabled,_that.repeatMode,_that.volume,_that.isAudioOnly,_that.session,_that.isVideoControlsVisible,_that.videoWidth,_that.videoHeight,_that.videoRotate,_that.audioParams,_that.audioTrack,_that.subtitleTrack,_that.availableAudioTracks,_that.availableSubtitleTracks,_that.externalAudioTracks,_that.externalSubtitleTracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  bool playing, @HiveField(1)  bool loading, @HiveField(2)  ProgressBarState progressBarState, @HiveField(5)  bool isFirst, @HiveField(6)  bool isLast, @HiveField(7)  bool shuffleEnabled, @HiveField(8)  AudioServiceRepeatMode repeatMode, @HiveField(9)  double volume, @HiveField(12)  bool isAudioOnly, @HiveField(13)  PlaybackSession? session,  bool isVideoControlsVisible,  int videoWidth,  int videoHeight,  int videoRotate,  String audioParams,  AudioTrack? audioTrack,  SubtitleTrack? subtitleTrack,  List<AudioTrack> availableAudioTracks,  List<SubtitleTrack> availableSubtitleTracks,  List<AudioTrack> externalAudioTracks,  List<SubtitleTrack> externalSubtitleTracks)  $default,) {final _that = this;
switch (_that) {
case _AppPlayerState():
return $default(_that.playing,_that.loading,_that.progressBarState,_that.isFirst,_that.isLast,_that.shuffleEnabled,_that.repeatMode,_that.volume,_that.isAudioOnly,_that.session,_that.isVideoControlsVisible,_that.videoWidth,_that.videoHeight,_that.videoRotate,_that.audioParams,_that.audioTrack,_that.subtitleTrack,_that.availableAudioTracks,_that.availableSubtitleTracks,_that.externalAudioTracks,_that.externalSubtitleTracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  bool playing, @HiveField(1)  bool loading, @HiveField(2)  ProgressBarState progressBarState, @HiveField(5)  bool isFirst, @HiveField(6)  bool isLast, @HiveField(7)  bool shuffleEnabled, @HiveField(8)  AudioServiceRepeatMode repeatMode, @HiveField(9)  double volume, @HiveField(12)  bool isAudioOnly, @HiveField(13)  PlaybackSession? session,  bool isVideoControlsVisible,  int videoWidth,  int videoHeight,  int videoRotate,  String audioParams,  AudioTrack? audioTrack,  SubtitleTrack? subtitleTrack,  List<AudioTrack> availableAudioTracks,  List<SubtitleTrack> availableSubtitleTracks,  List<AudioTrack> externalAudioTracks,  List<SubtitleTrack> externalSubtitleTracks)?  $default,) {final _that = this;
switch (_that) {
case _AppPlayerState() when $default != null:
return $default(_that.playing,_that.loading,_that.progressBarState,_that.isFirst,_that.isLast,_that.shuffleEnabled,_that.repeatMode,_that.volume,_that.isAudioOnly,_that.session,_that.isVideoControlsVisible,_that.videoWidth,_that.videoHeight,_that.videoRotate,_that.audioParams,_that.audioTrack,_that.subtitleTrack,_that.availableAudioTracks,_that.availableSubtitleTracks,_that.externalAudioTracks,_that.externalSubtitleTracks);case _:
  return null;

}
}

}

/// @nodoc


class _AppPlayerState extends AppPlayerState {
  const _AppPlayerState({@HiveField(0) this.playing = false, @HiveField(1) this.loading = false, @HiveField(2) this.progressBarState = const ProgressBarState(current: Duration.zero, buffered: Duration.zero, total: Duration.zero), @HiveField(5) this.isFirst = true, @HiveField(6) this.isLast = true, @HiveField(7) this.shuffleEnabled = false, @HiveField(8) this.repeatMode = AudioServiceRepeatMode.none, @HiveField(9) this.volume = 1.0, @HiveField(12) this.isAudioOnly = false, @HiveField(13) this.session, this.isVideoControlsVisible = true, this.videoWidth = 0, this.videoHeight = 0, this.videoRotate = 0, this.audioParams = '', this.audioTrack, this.subtitleTrack, final  List<AudioTrack> availableAudioTracks = const [], final  List<SubtitleTrack> availableSubtitleTracks = const [], final  List<AudioTrack> externalAudioTracks = const [], final  List<SubtitleTrack> externalSubtitleTracks = const []}): _availableAudioTracks = availableAudioTracks,_availableSubtitleTracks = availableSubtitleTracks,_externalAudioTracks = externalAudioTracks,_externalSubtitleTracks = externalSubtitleTracks,super._();
  

@override@JsonKey()@HiveField(0) final  bool playing;
@override@JsonKey()@HiveField(1) final  bool loading;
@override@JsonKey()@HiveField(2) final  ProgressBarState progressBarState;
@override@JsonKey()@HiveField(5) final  bool isFirst;
@override@JsonKey()@HiveField(6) final  bool isLast;
@override@JsonKey()@HiveField(7) final  bool shuffleEnabled;
@override@JsonKey()@HiveField(8) final  AudioServiceRepeatMode repeatMode;
@override@JsonKey()@HiveField(9) final  double volume;
@override@JsonKey()@HiveField(12) final  bool isAudioOnly;
@override@HiveField(13) final  PlaybackSession? session;
@override@JsonKey() final  bool isVideoControlsVisible;
@override@JsonKey() final  int videoWidth;
@override@JsonKey() final  int videoHeight;
@override@JsonKey() final  int videoRotate;
@override@JsonKey() final  String audioParams;
@override final  AudioTrack? audioTrack;
@override final  SubtitleTrack? subtitleTrack;
 final  List<AudioTrack> _availableAudioTracks;
@override@JsonKey() List<AudioTrack> get availableAudioTracks {
  if (_availableAudioTracks is EqualUnmodifiableListView) return _availableAudioTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableAudioTracks);
}

 final  List<SubtitleTrack> _availableSubtitleTracks;
@override@JsonKey() List<SubtitleTrack> get availableSubtitleTracks {
  if (_availableSubtitleTracks is EqualUnmodifiableListView) return _availableSubtitleTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableSubtitleTracks);
}

// 外部挂载的轨道列??
 final  List<AudioTrack> _externalAudioTracks;
// 外部挂载的轨道列??
@override@JsonKey() List<AudioTrack> get externalAudioTracks {
  if (_externalAudioTracks is EqualUnmodifiableListView) return _externalAudioTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_externalAudioTracks);
}

 final  List<SubtitleTrack> _externalSubtitleTracks;
@override@JsonKey() List<SubtitleTrack> get externalSubtitleTracks {
  if (_externalSubtitleTracks is EqualUnmodifiableListView) return _externalSubtitleTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_externalSubtitleTracks);
}


/// Create a copy of AppPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppPlayerStateCopyWith<_AppPlayerState> get copyWith => __$AppPlayerStateCopyWithImpl<_AppPlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppPlayerState&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.progressBarState, progressBarState) || other.progressBarState == progressBarState)&&(identical(other.isFirst, isFirst) || other.isFirst == isFirst)&&(identical(other.isLast, isLast) || other.isLast == isLast)&&(identical(other.shuffleEnabled, shuffleEnabled) || other.shuffleEnabled == shuffleEnabled)&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.isAudioOnly, isAudioOnly) || other.isAudioOnly == isAudioOnly)&&(identical(other.session, session) || other.session == session)&&(identical(other.isVideoControlsVisible, isVideoControlsVisible) || other.isVideoControlsVisible == isVideoControlsVisible)&&(identical(other.videoWidth, videoWidth) || other.videoWidth == videoWidth)&&(identical(other.videoHeight, videoHeight) || other.videoHeight == videoHeight)&&(identical(other.videoRotate, videoRotate) || other.videoRotate == videoRotate)&&(identical(other.audioParams, audioParams) || other.audioParams == audioParams)&&(identical(other.audioTrack, audioTrack) || other.audioTrack == audioTrack)&&(identical(other.subtitleTrack, subtitleTrack) || other.subtitleTrack == subtitleTrack)&&const DeepCollectionEquality().equals(other._availableAudioTracks, _availableAudioTracks)&&const DeepCollectionEquality().equals(other._availableSubtitleTracks, _availableSubtitleTracks)&&const DeepCollectionEquality().equals(other._externalAudioTracks, _externalAudioTracks)&&const DeepCollectionEquality().equals(other._externalSubtitleTracks, _externalSubtitleTracks));
}


@override
int get hashCode => Object.hashAll([runtimeType,playing,loading,progressBarState,isFirst,isLast,shuffleEnabled,repeatMode,volume,isAudioOnly,session,isVideoControlsVisible,videoWidth,videoHeight,videoRotate,audioParams,audioTrack,subtitleTrack,const DeepCollectionEquality().hash(_availableAudioTracks),const DeepCollectionEquality().hash(_availableSubtitleTracks),const DeepCollectionEquality().hash(_externalAudioTracks),const DeepCollectionEquality().hash(_externalSubtitleTracks)]);

@override
String toString() {
  return 'AppPlayerState(playing: $playing, loading: $loading, progressBarState: $progressBarState, isFirst: $isFirst, isLast: $isLast, shuffleEnabled: $shuffleEnabled, repeatMode: $repeatMode, volume: $volume, isAudioOnly: $isAudioOnly, session: $session, isVideoControlsVisible: $isVideoControlsVisible, videoWidth: $videoWidth, videoHeight: $videoHeight, videoRotate: $videoRotate, audioParams: $audioParams, audioTrack: $audioTrack, subtitleTrack: $subtitleTrack, availableAudioTracks: $availableAudioTracks, availableSubtitleTracks: $availableSubtitleTracks, externalAudioTracks: $externalAudioTracks, externalSubtitleTracks: $externalSubtitleTracks)';
}


}

/// @nodoc
abstract mixin class _$AppPlayerStateCopyWith<$Res> implements $AppPlayerStateCopyWith<$Res> {
  factory _$AppPlayerStateCopyWith(_AppPlayerState value, $Res Function(_AppPlayerState) _then) = __$AppPlayerStateCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) bool playing,@HiveField(1) bool loading,@HiveField(2) ProgressBarState progressBarState,@HiveField(5) bool isFirst,@HiveField(6) bool isLast,@HiveField(7) bool shuffleEnabled,@HiveField(8) AudioServiceRepeatMode repeatMode,@HiveField(9) double volume,@HiveField(12) bool isAudioOnly,@HiveField(13) PlaybackSession? session, bool isVideoControlsVisible, int videoWidth, int videoHeight, int videoRotate, String audioParams, AudioTrack? audioTrack, SubtitleTrack? subtitleTrack, List<AudioTrack> availableAudioTracks, List<SubtitleTrack> availableSubtitleTracks, List<AudioTrack> externalAudioTracks, List<SubtitleTrack> externalSubtitleTracks
});


@override $PlaybackSessionCopyWith<$Res>? get session;

}
/// @nodoc
class __$AppPlayerStateCopyWithImpl<$Res>
    implements _$AppPlayerStateCopyWith<$Res> {
  __$AppPlayerStateCopyWithImpl(this._self, this._then);

  final _AppPlayerState _self;
  final $Res Function(_AppPlayerState) _then;

/// Create a copy of AppPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playing = null,Object? loading = null,Object? progressBarState = null,Object? isFirst = null,Object? isLast = null,Object? shuffleEnabled = null,Object? repeatMode = null,Object? volume = null,Object? isAudioOnly = null,Object? session = freezed,Object? isVideoControlsVisible = null,Object? videoWidth = null,Object? videoHeight = null,Object? videoRotate = null,Object? audioParams = null,Object? audioTrack = freezed,Object? subtitleTrack = freezed,Object? availableAudioTracks = null,Object? availableSubtitleTracks = null,Object? externalAudioTracks = null,Object? externalSubtitleTracks = null,}) {
  return _then(_AppPlayerState(
playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,progressBarState: null == progressBarState ? _self.progressBarState : progressBarState // ignore: cast_nullable_to_non_nullable
as ProgressBarState,isFirst: null == isFirst ? _self.isFirst : isFirst // ignore: cast_nullable_to_non_nullable
as bool,isLast: null == isLast ? _self.isLast : isLast // ignore: cast_nullable_to_non_nullable
as bool,shuffleEnabled: null == shuffleEnabled ? _self.shuffleEnabled : shuffleEnabled // ignore: cast_nullable_to_non_nullable
as bool,repeatMode: null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as AudioServiceRepeatMode,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,isAudioOnly: null == isAudioOnly ? _self.isAudioOnly : isAudioOnly // ignore: cast_nullable_to_non_nullable
as bool,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as PlaybackSession?,isVideoControlsVisible: null == isVideoControlsVisible ? _self.isVideoControlsVisible : isVideoControlsVisible // ignore: cast_nullable_to_non_nullable
as bool,videoWidth: null == videoWidth ? _self.videoWidth : videoWidth // ignore: cast_nullable_to_non_nullable
as int,videoHeight: null == videoHeight ? _self.videoHeight : videoHeight // ignore: cast_nullable_to_non_nullable
as int,videoRotate: null == videoRotate ? _self.videoRotate : videoRotate // ignore: cast_nullable_to_non_nullable
as int,audioParams: null == audioParams ? _self.audioParams : audioParams // ignore: cast_nullable_to_non_nullable
as String,audioTrack: freezed == audioTrack ? _self.audioTrack : audioTrack // ignore: cast_nullable_to_non_nullable
as AudioTrack?,subtitleTrack: freezed == subtitleTrack ? _self.subtitleTrack : subtitleTrack // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,availableAudioTracks: null == availableAudioTracks ? _self._availableAudioTracks : availableAudioTracks // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,availableSubtitleTracks: null == availableSubtitleTracks ? _self._availableSubtitleTracks : availableSubtitleTracks // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,externalAudioTracks: null == externalAudioTracks ? _self._externalAudioTracks : externalAudioTracks // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,externalSubtitleTracks: null == externalSubtitleTracks ? _self._externalSubtitleTracks : externalSubtitleTracks // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,
  ));
}

/// Create a copy of AppPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $PlaybackSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
