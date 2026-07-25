// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lyrics_match_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LyricsMatchState {

 int? get currentWorkId; Map<String, FileNode?> get subtitleMapping; List<FileNode> get lyricsList; bool get isSearching;
/// Create a copy of LyricsMatchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricsMatchStateCopyWith<LyricsMatchState> get copyWith => _$LyricsMatchStateCopyWithImpl<LyricsMatchState>(this as LyricsMatchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricsMatchState&&(identical(other.currentWorkId, currentWorkId) || other.currentWorkId == currentWorkId)&&const DeepCollectionEquality().equals(other.subtitleMapping, subtitleMapping)&&const DeepCollectionEquality().equals(other.lyricsList, lyricsList)&&(identical(other.isSearching, isSearching) || other.isSearching == isSearching));
}


@override
int get hashCode => Object.hash(runtimeType,currentWorkId,const DeepCollectionEquality().hash(subtitleMapping),const DeepCollectionEquality().hash(lyricsList),isSearching);

@override
String toString() {
  return 'LyricsMatchState(currentWorkId: $currentWorkId, subtitleMapping: $subtitleMapping, lyricsList: $lyricsList, isSearching: $isSearching)';
}


}

/// @nodoc
abstract mixin class $LyricsMatchStateCopyWith<$Res>  {
  factory $LyricsMatchStateCopyWith(LyricsMatchState value, $Res Function(LyricsMatchState) _then) = _$LyricsMatchStateCopyWithImpl;
@useResult
$Res call({
 int? currentWorkId, Map<String, FileNode?> subtitleMapping, List<FileNode> lyricsList, bool isSearching
});




}
/// @nodoc
class _$LyricsMatchStateCopyWithImpl<$Res>
    implements $LyricsMatchStateCopyWith<$Res> {
  _$LyricsMatchStateCopyWithImpl(this._self, this._then);

  final LyricsMatchState _self;
  final $Res Function(LyricsMatchState) _then;

/// Create a copy of LyricsMatchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentWorkId = freezed,Object? subtitleMapping = null,Object? lyricsList = null,Object? isSearching = null,}) {
  return _then(_self.copyWith(
currentWorkId: freezed == currentWorkId ? _self.currentWorkId : currentWorkId // ignore: cast_nullable_to_non_nullable
as int?,subtitleMapping: null == subtitleMapping ? _self.subtitleMapping : subtitleMapping // ignore: cast_nullable_to_non_nullable
as Map<String, FileNode?>,lyricsList: null == lyricsList ? _self.lyricsList : lyricsList // ignore: cast_nullable_to_non_nullable
as List<FileNode>,isSearching: null == isSearching ? _self.isSearching : isSearching // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricsMatchState].
extension LyricsMatchStatePatterns on LyricsMatchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricsMatchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricsMatchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricsMatchState value)  $default,){
final _that = this;
switch (_that) {
case _LyricsMatchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricsMatchState value)?  $default,){
final _that = this;
switch (_that) {
case _LyricsMatchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? currentWorkId,  Map<String, FileNode?> subtitleMapping,  List<FileNode> lyricsList,  bool isSearching)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricsMatchState() when $default != null:
return $default(_that.currentWorkId,_that.subtitleMapping,_that.lyricsList,_that.isSearching);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? currentWorkId,  Map<String, FileNode?> subtitleMapping,  List<FileNode> lyricsList,  bool isSearching)  $default,) {final _that = this;
switch (_that) {
case _LyricsMatchState():
return $default(_that.currentWorkId,_that.subtitleMapping,_that.lyricsList,_that.isSearching);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? currentWorkId,  Map<String, FileNode?> subtitleMapping,  List<FileNode> lyricsList,  bool isSearching)?  $default,) {final _that = this;
switch (_that) {
case _LyricsMatchState() when $default != null:
return $default(_that.currentWorkId,_that.subtitleMapping,_that.lyricsList,_that.isSearching);case _:
  return null;

}
}

}

/// @nodoc


class _LyricsMatchState implements LyricsMatchState {
  const _LyricsMatchState({this.currentWorkId = null, final  Map<String, FileNode?> subtitleMapping = const {}, final  List<FileNode> lyricsList = const [], this.isSearching = false}): _subtitleMapping = subtitleMapping,_lyricsList = lyricsList;
  

@override@JsonKey() final  int? currentWorkId;
 final  Map<String, FileNode?> _subtitleMapping;
@override@JsonKey() Map<String, FileNode?> get subtitleMapping {
  if (_subtitleMapping is EqualUnmodifiableMapView) return _subtitleMapping;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_subtitleMapping);
}

 final  List<FileNode> _lyricsList;
@override@JsonKey() List<FileNode> get lyricsList {
  if (_lyricsList is EqualUnmodifiableListView) return _lyricsList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lyricsList);
}

@override@JsonKey() final  bool isSearching;

/// Create a copy of LyricsMatchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricsMatchStateCopyWith<_LyricsMatchState> get copyWith => __$LyricsMatchStateCopyWithImpl<_LyricsMatchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricsMatchState&&(identical(other.currentWorkId, currentWorkId) || other.currentWorkId == currentWorkId)&&const DeepCollectionEquality().equals(other._subtitleMapping, _subtitleMapping)&&const DeepCollectionEquality().equals(other._lyricsList, _lyricsList)&&(identical(other.isSearching, isSearching) || other.isSearching == isSearching));
}


@override
int get hashCode => Object.hash(runtimeType,currentWorkId,const DeepCollectionEquality().hash(_subtitleMapping),const DeepCollectionEquality().hash(_lyricsList),isSearching);

@override
String toString() {
  return 'LyricsMatchState(currentWorkId: $currentWorkId, subtitleMapping: $subtitleMapping, lyricsList: $lyricsList, isSearching: $isSearching)';
}


}

/// @nodoc
abstract mixin class _$LyricsMatchStateCopyWith<$Res> implements $LyricsMatchStateCopyWith<$Res> {
  factory _$LyricsMatchStateCopyWith(_LyricsMatchState value, $Res Function(_LyricsMatchState) _then) = __$LyricsMatchStateCopyWithImpl;
@override @useResult
$Res call({
 int? currentWorkId, Map<String, FileNode?> subtitleMapping, List<FileNode> lyricsList, bool isSearching
});




}
/// @nodoc
class __$LyricsMatchStateCopyWithImpl<$Res>
    implements _$LyricsMatchStateCopyWith<$Res> {
  __$LyricsMatchStateCopyWithImpl(this._self, this._then);

  final _LyricsMatchState _self;
  final $Res Function(_LyricsMatchState) _then;

/// Create a copy of LyricsMatchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentWorkId = freezed,Object? subtitleMapping = null,Object? lyricsList = null,Object? isSearching = null,}) {
  return _then(_LyricsMatchState(
currentWorkId: freezed == currentWorkId ? _self.currentWorkId : currentWorkId // ignore: cast_nullable_to_non_nullable
as int?,subtitleMapping: null == subtitleMapping ? _self._subtitleMapping : subtitleMapping // ignore: cast_nullable_to_non_nullable
as Map<String, FileNode?>,lyricsList: null == lyricsList ? _self._lyricsList : lyricsList // ignore: cast_nullable_to_non_nullable
as List<FileNode>,isSearching: null == isSearching ? _self.isSearching : isSearching // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
