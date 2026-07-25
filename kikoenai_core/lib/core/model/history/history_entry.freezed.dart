// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryEntry {

@HiveField(6) PlaybackSession get session;@HiveField(7) String get lastItemId;@HiveField(8) int get lastPlayTime;@HiveField(9) int? get lastProgressMs;
/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryEntryCopyWith<HistoryEntry> get copyWith => _$HistoryEntryCopyWithImpl<HistoryEntry>(this as HistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryEntry&&(identical(other.session, session) || other.session == session)&&(identical(other.lastItemId, lastItemId) || other.lastItemId == lastItemId)&&(identical(other.lastPlayTime, lastPlayTime) || other.lastPlayTime == lastPlayTime)&&(identical(other.lastProgressMs, lastProgressMs) || other.lastProgressMs == lastProgressMs));
}


@override
int get hashCode => Object.hash(runtimeType,session,lastItemId,lastPlayTime,lastProgressMs);

@override
String toString() {
  return 'HistoryEntry(session: $session, lastItemId: $lastItemId, lastPlayTime: $lastPlayTime, lastProgressMs: $lastProgressMs)';
}


}

/// @nodoc
abstract mixin class $HistoryEntryCopyWith<$Res>  {
  factory $HistoryEntryCopyWith(HistoryEntry value, $Res Function(HistoryEntry) _then) = _$HistoryEntryCopyWithImpl;
@useResult
$Res call({
@HiveField(6) PlaybackSession session,@HiveField(7) String lastItemId,@HiveField(8) int lastPlayTime,@HiveField(9) int? lastProgressMs
});


$PlaybackSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$HistoryEntryCopyWithImpl<$Res>
    implements $HistoryEntryCopyWith<$Res> {
  _$HistoryEntryCopyWithImpl(this._self, this._then);

  final HistoryEntry _self;
  final $Res Function(HistoryEntry) _then;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? lastItemId = null,Object? lastPlayTime = null,Object? lastProgressMs = freezed,}) {
  return _then(_self.copyWith(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as PlaybackSession,lastItemId: null == lastItemId ? _self.lastItemId : lastItemId // ignore: cast_nullable_to_non_nullable
as String,lastPlayTime: null == lastPlayTime ? _self.lastPlayTime : lastPlayTime // ignore: cast_nullable_to_non_nullable
as int,lastProgressMs: freezed == lastProgressMs ? _self.lastProgressMs : lastProgressMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackSessionCopyWith<$Res> get session {
  
  return $PlaybackSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [HistoryEntry].
extension HistoryEntryPatterns on HistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _HistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(6)  PlaybackSession session, @HiveField(7)  String lastItemId, @HiveField(8)  int lastPlayTime, @HiveField(9)  int? lastProgressMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
return $default(_that.session,_that.lastItemId,_that.lastPlayTime,_that.lastProgressMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(6)  PlaybackSession session, @HiveField(7)  String lastItemId, @HiveField(8)  int lastPlayTime, @HiveField(9)  int? lastProgressMs)  $default,) {final _that = this;
switch (_that) {
case _HistoryEntry():
return $default(_that.session,_that.lastItemId,_that.lastPlayTime,_that.lastProgressMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(6)  PlaybackSession session, @HiveField(7)  String lastItemId, @HiveField(8)  int lastPlayTime, @HiveField(9)  int? lastProgressMs)?  $default,) {final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
return $default(_that.session,_that.lastItemId,_that.lastPlayTime,_that.lastProgressMs);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryEntry extends HistoryEntry {
  const _HistoryEntry({@HiveField(6) required this.session, @HiveField(7) required this.lastItemId, @HiveField(8) required this.lastPlayTime, @HiveField(9) this.lastProgressMs}): super._();
  

@override@HiveField(6) final  PlaybackSession session;
@override@HiveField(7) final  String lastItemId;
@override@HiveField(8) final  int lastPlayTime;
@override@HiveField(9) final  int? lastProgressMs;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryEntryCopyWith<_HistoryEntry> get copyWith => __$HistoryEntryCopyWithImpl<_HistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryEntry&&(identical(other.session, session) || other.session == session)&&(identical(other.lastItemId, lastItemId) || other.lastItemId == lastItemId)&&(identical(other.lastPlayTime, lastPlayTime) || other.lastPlayTime == lastPlayTime)&&(identical(other.lastProgressMs, lastProgressMs) || other.lastProgressMs == lastProgressMs));
}


@override
int get hashCode => Object.hash(runtimeType,session,lastItemId,lastPlayTime,lastProgressMs);

@override
String toString() {
  return 'HistoryEntry(session: $session, lastItemId: $lastItemId, lastPlayTime: $lastPlayTime, lastProgressMs: $lastProgressMs)';
}


}

/// @nodoc
abstract mixin class _$HistoryEntryCopyWith<$Res> implements $HistoryEntryCopyWith<$Res> {
  factory _$HistoryEntryCopyWith(_HistoryEntry value, $Res Function(_HistoryEntry) _then) = __$HistoryEntryCopyWithImpl;
@override @useResult
$Res call({
@HiveField(6) PlaybackSession session,@HiveField(7) String lastItemId,@HiveField(8) int lastPlayTime,@HiveField(9) int? lastProgressMs
});


@override $PlaybackSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$HistoryEntryCopyWithImpl<$Res>
    implements _$HistoryEntryCopyWith<$Res> {
  __$HistoryEntryCopyWithImpl(this._self, this._then);

  final _HistoryEntry _self;
  final $Res Function(_HistoryEntry) _then;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? lastItemId = null,Object? lastPlayTime = null,Object? lastProgressMs = freezed,}) {
  return _then(_HistoryEntry(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as PlaybackSession,lastItemId: null == lastItemId ? _self.lastItemId : lastItemId // ignore: cast_nullable_to_non_nullable
as String,lastPlayTime: null == lastPlayTime ? _self.lastPlayTime : lastPlayTime // ignore: cast_nullable_to_non_nullable
as int,lastProgressMs: freezed == lastProgressMs ? _self.lastProgressMs : lastProgressMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackSessionCopyWith<$Res> get session {
  
  return $PlaybackSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
