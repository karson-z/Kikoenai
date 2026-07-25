// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_queue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerQueue {

 String? get workId; List<FileNode> get playlist; String? get lastPlayTrackId; int get progressMs;
/// Create a copy of PlayerQueue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerQueueCopyWith<PlayerQueue> get copyWith => _$PlayerQueueCopyWithImpl<PlayerQueue>(this as PlayerQueue, _$identity);

  /// Serializes this PlayerQueue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerQueue&&(identical(other.workId, workId) || other.workId == workId)&&const DeepCollectionEquality().equals(other.playlist, playlist)&&(identical(other.lastPlayTrackId, lastPlayTrackId) || other.lastPlayTrackId == lastPlayTrackId)&&(identical(other.progressMs, progressMs) || other.progressMs == progressMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workId,const DeepCollectionEquality().hash(playlist),lastPlayTrackId,progressMs);

@override
String toString() {
  return 'PlayerQueue(workId: $workId, playlist: $playlist, lastPlayTrackId: $lastPlayTrackId, progressMs: $progressMs)';
}


}

/// @nodoc
abstract mixin class $PlayerQueueCopyWith<$Res>  {
  factory $PlayerQueueCopyWith(PlayerQueue value, $Res Function(PlayerQueue) _then) = _$PlayerQueueCopyWithImpl;
@useResult
$Res call({
 String? workId, List<FileNode> playlist, String? lastPlayTrackId, int progressMs
});




}
/// @nodoc
class _$PlayerQueueCopyWithImpl<$Res>
    implements $PlayerQueueCopyWith<$Res> {
  _$PlayerQueueCopyWithImpl(this._self, this._then);

  final PlayerQueue _self;
  final $Res Function(PlayerQueue) _then;

/// Create a copy of PlayerQueue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workId = freezed,Object? playlist = null,Object? lastPlayTrackId = freezed,Object? progressMs = null,}) {
  return _then(_self.copyWith(
workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String?,playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as List<FileNode>,lastPlayTrackId: freezed == lastPlayTrackId ? _self.lastPlayTrackId : lastPlayTrackId // ignore: cast_nullable_to_non_nullable
as String?,progressMs: null == progressMs ? _self.progressMs : progressMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerQueue].
extension PlayerQueuePatterns on PlayerQueue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerQueue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerQueue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerQueue value)  $default,){
final _that = this;
switch (_that) {
case _PlayerQueue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerQueue value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerQueue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? workId,  List<FileNode> playlist,  String? lastPlayTrackId,  int progressMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerQueue() when $default != null:
return $default(_that.workId,_that.playlist,_that.lastPlayTrackId,_that.progressMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? workId,  List<FileNode> playlist,  String? lastPlayTrackId,  int progressMs)  $default,) {final _that = this;
switch (_that) {
case _PlayerQueue():
return $default(_that.workId,_that.playlist,_that.lastPlayTrackId,_that.progressMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? workId,  List<FileNode> playlist,  String? lastPlayTrackId,  int progressMs)?  $default,) {final _that = this;
switch (_that) {
case _PlayerQueue() when $default != null:
return $default(_that.workId,_that.playlist,_that.lastPlayTrackId,_that.progressMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerQueue implements PlayerQueue {
  const _PlayerQueue({this.workId, required final  List<FileNode> playlist, this.lastPlayTrackId, this.progressMs = 0}): _playlist = playlist;
  factory _PlayerQueue.fromJson(Map<String, dynamic> json) => _$PlayerQueueFromJson(json);

@override final  String? workId;
 final  List<FileNode> _playlist;
@override List<FileNode> get playlist {
  if (_playlist is EqualUnmodifiableListView) return _playlist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlist);
}

@override final  String? lastPlayTrackId;
@override@JsonKey() final  int progressMs;

/// Create a copy of PlayerQueue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerQueueCopyWith<_PlayerQueue> get copyWith => __$PlayerQueueCopyWithImpl<_PlayerQueue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerQueueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerQueue&&(identical(other.workId, workId) || other.workId == workId)&&const DeepCollectionEquality().equals(other._playlist, _playlist)&&(identical(other.lastPlayTrackId, lastPlayTrackId) || other.lastPlayTrackId == lastPlayTrackId)&&(identical(other.progressMs, progressMs) || other.progressMs == progressMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workId,const DeepCollectionEquality().hash(_playlist),lastPlayTrackId,progressMs);

@override
String toString() {
  return 'PlayerQueue(workId: $workId, playlist: $playlist, lastPlayTrackId: $lastPlayTrackId, progressMs: $progressMs)';
}


}

/// @nodoc
abstract mixin class _$PlayerQueueCopyWith<$Res> implements $PlayerQueueCopyWith<$Res> {
  factory _$PlayerQueueCopyWith(_PlayerQueue value, $Res Function(_PlayerQueue) _then) = __$PlayerQueueCopyWithImpl;
@override @useResult
$Res call({
 String? workId, List<FileNode> playlist, String? lastPlayTrackId, int progressMs
});




}
/// @nodoc
class __$PlayerQueueCopyWithImpl<$Res>
    implements _$PlayerQueueCopyWith<$Res> {
  __$PlayerQueueCopyWithImpl(this._self, this._then);

  final _PlayerQueue _self;
  final $Res Function(_PlayerQueue) _then;

/// Create a copy of PlayerQueue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workId = freezed,Object? playlist = null,Object? lastPlayTrackId = freezed,Object? progressMs = null,}) {
  return _then(_PlayerQueue(
workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String?,playlist: null == playlist ? _self._playlist : playlist // ignore: cast_nullable_to_non_nullable
as List<FileNode>,lastPlayTrackId: freezed == lastPlayTrackId ? _self.lastPlayTrackId : lastPlayTrackId // ignore: cast_nullable_to_non_nullable
as String?,progressMs: null == progressMs ? _self.progressMs : progressMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlayerQueueWithLastPlayDate {

 PlayerQueue get queue; DateTime get lastPlayDate;
/// Create a copy of PlayerQueueWithLastPlayDate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerQueueWithLastPlayDateCopyWith<PlayerQueueWithLastPlayDate> get copyWith => _$PlayerQueueWithLastPlayDateCopyWithImpl<PlayerQueueWithLastPlayDate>(this as PlayerQueueWithLastPlayDate, _$identity);

  /// Serializes this PlayerQueueWithLastPlayDate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerQueueWithLastPlayDate&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.lastPlayDate, lastPlayDate) || other.lastPlayDate == lastPlayDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,queue,lastPlayDate);

@override
String toString() {
  return 'PlayerQueueWithLastPlayDate(queue: $queue, lastPlayDate: $lastPlayDate)';
}


}

/// @nodoc
abstract mixin class $PlayerQueueWithLastPlayDateCopyWith<$Res>  {
  factory $PlayerQueueWithLastPlayDateCopyWith(PlayerQueueWithLastPlayDate value, $Res Function(PlayerQueueWithLastPlayDate) _then) = _$PlayerQueueWithLastPlayDateCopyWithImpl;
@useResult
$Res call({
 PlayerQueue queue, DateTime lastPlayDate
});


$PlayerQueueCopyWith<$Res> get queue;

}
/// @nodoc
class _$PlayerQueueWithLastPlayDateCopyWithImpl<$Res>
    implements $PlayerQueueWithLastPlayDateCopyWith<$Res> {
  _$PlayerQueueWithLastPlayDateCopyWithImpl(this._self, this._then);

  final PlayerQueueWithLastPlayDate _self;
  final $Res Function(PlayerQueueWithLastPlayDate) _then;

/// Create a copy of PlayerQueueWithLastPlayDate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,Object? lastPlayDate = null,}) {
  return _then(_self.copyWith(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as PlayerQueue,lastPlayDate: null == lastPlayDate ? _self.lastPlayDate : lastPlayDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of PlayerQueueWithLastPlayDate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerQueueCopyWith<$Res> get queue {
  
  return $PlayerQueueCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerQueueWithLastPlayDate].
extension PlayerQueueWithLastPlayDatePatterns on PlayerQueueWithLastPlayDate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerQueueWithLastPlayDate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerQueueWithLastPlayDate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerQueueWithLastPlayDate value)  $default,){
final _that = this;
switch (_that) {
case _PlayerQueueWithLastPlayDate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerQueueWithLastPlayDate value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerQueueWithLastPlayDate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerQueue queue,  DateTime lastPlayDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerQueueWithLastPlayDate() when $default != null:
return $default(_that.queue,_that.lastPlayDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerQueue queue,  DateTime lastPlayDate)  $default,) {final _that = this;
switch (_that) {
case _PlayerQueueWithLastPlayDate():
return $default(_that.queue,_that.lastPlayDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerQueue queue,  DateTime lastPlayDate)?  $default,) {final _that = this;
switch (_that) {
case _PlayerQueueWithLastPlayDate() when $default != null:
return $default(_that.queue,_that.lastPlayDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerQueueWithLastPlayDate implements PlayerQueueWithLastPlayDate {
  const _PlayerQueueWithLastPlayDate({required this.queue, required this.lastPlayDate});
  factory _PlayerQueueWithLastPlayDate.fromJson(Map<String, dynamic> json) => _$PlayerQueueWithLastPlayDateFromJson(json);

@override final  PlayerQueue queue;
@override final  DateTime lastPlayDate;

/// Create a copy of PlayerQueueWithLastPlayDate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerQueueWithLastPlayDateCopyWith<_PlayerQueueWithLastPlayDate> get copyWith => __$PlayerQueueWithLastPlayDateCopyWithImpl<_PlayerQueueWithLastPlayDate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerQueueWithLastPlayDateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerQueueWithLastPlayDate&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.lastPlayDate, lastPlayDate) || other.lastPlayDate == lastPlayDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,queue,lastPlayDate);

@override
String toString() {
  return 'PlayerQueueWithLastPlayDate(queue: $queue, lastPlayDate: $lastPlayDate)';
}


}

/// @nodoc
abstract mixin class _$PlayerQueueWithLastPlayDateCopyWith<$Res> implements $PlayerQueueWithLastPlayDateCopyWith<$Res> {
  factory _$PlayerQueueWithLastPlayDateCopyWith(_PlayerQueueWithLastPlayDate value, $Res Function(_PlayerQueueWithLastPlayDate) _then) = __$PlayerQueueWithLastPlayDateCopyWithImpl;
@override @useResult
$Res call({
 PlayerQueue queue, DateTime lastPlayDate
});


@override $PlayerQueueCopyWith<$Res> get queue;

}
/// @nodoc
class __$PlayerQueueWithLastPlayDateCopyWithImpl<$Res>
    implements _$PlayerQueueWithLastPlayDateCopyWith<$Res> {
  __$PlayerQueueWithLastPlayDateCopyWithImpl(this._self, this._then);

  final _PlayerQueueWithLastPlayDate _self;
  final $Res Function(_PlayerQueueWithLastPlayDate) _then;

/// Create a copy of PlayerQueueWithLastPlayDate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? lastPlayDate = null,}) {
  return _then(_PlayerQueueWithLastPlayDate(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as PlayerQueue,lastPlayDate: null == lastPlayDate ? _self.lastPlayDate : lastPlayDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of PlayerQueueWithLastPlayDate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerQueueCopyWith<$Res> get queue {
  
  return $PlayerQueueCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}
}

// dart format on
