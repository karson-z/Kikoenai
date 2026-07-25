// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackItem {

@HiveField(0) String get id;@HiveField(1) String get url;@HiveField(2) String get title;@HiveField(3) bool get isVideo;@HiveField(4) NodeSource get source;/// Historical aggregation id.
///
/// Tracks in the same network work or local work share a scopeId. Local
/// singles usually use their own item id as the scopeId.
@HiveField(5) String get scopeId;@HiveField(6) int? get workId;@HiveField(7) String? get albumTitle;@HiveField(8) String? get artist;@HiveField(9) String? get coverUrl;@HiveField(10) String? get smallCoverUrl;@HiveField(11) int? get durationMs;
/// Create a copy of PlaybackItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackItemCopyWith<PlaybackItem> get copyWith => _$PlaybackItemCopyWithImpl<PlaybackItem>(this as PlaybackItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackItem&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.isVideo, isVideo) || other.isVideo == isVideo)&&(identical(other.source, source) || other.source == source)&&(identical(other.scopeId, scopeId) || other.scopeId == scopeId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.albumTitle, albumTitle) || other.albumTitle == albumTitle)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.smallCoverUrl, smallCoverUrl) || other.smallCoverUrl == smallCoverUrl)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,title,isVideo,source,scopeId,workId,albumTitle,artist,coverUrl,smallCoverUrl,durationMs);

@override
String toString() {
  return 'PlaybackItem(id: $id, url: $url, title: $title, isVideo: $isVideo, source: $source, scopeId: $scopeId, workId: $workId, albumTitle: $albumTitle, artist: $artist, coverUrl: $coverUrl, smallCoverUrl: $smallCoverUrl, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $PlaybackItemCopyWith<$Res>  {
  factory $PlaybackItemCopyWith(PlaybackItem value, $Res Function(PlaybackItem) _then) = _$PlaybackItemCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String url,@HiveField(2) String title,@HiveField(3) bool isVideo,@HiveField(4) NodeSource source,@HiveField(5) String scopeId,@HiveField(6) int? workId,@HiveField(7) String? albumTitle,@HiveField(8) String? artist,@HiveField(9) String? coverUrl,@HiveField(10) String? smallCoverUrl,@HiveField(11) int? durationMs
});




}
/// @nodoc
class _$PlaybackItemCopyWithImpl<$Res>
    implements $PlaybackItemCopyWith<$Res> {
  _$PlaybackItemCopyWithImpl(this._self, this._then);

  final PlaybackItem _self;
  final $Res Function(PlaybackItem) _then;

/// Create a copy of PlaybackItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? title = null,Object? isVideo = null,Object? source = null,Object? scopeId = null,Object? workId = freezed,Object? albumTitle = freezed,Object? artist = freezed,Object? coverUrl = freezed,Object? smallCoverUrl = freezed,Object? durationMs = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,isVideo: null == isVideo ? _self.isVideo : isVideo // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NodeSource,scopeId: null == scopeId ? _self.scopeId : scopeId // ignore: cast_nullable_to_non_nullable
as String,workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as int?,albumTitle: freezed == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,smallCoverUrl: freezed == smallCoverUrl ? _self.smallCoverUrl : smallCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackItem].
extension PlaybackItemPatterns on PlaybackItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackItem value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String url, @HiveField(2)  String title, @HiveField(3)  bool isVideo, @HiveField(4)  NodeSource source, @HiveField(5)  String scopeId, @HiveField(6)  int? workId, @HiveField(7)  String? albumTitle, @HiveField(8)  String? artist, @HiveField(9)  String? coverUrl, @HiveField(10)  String? smallCoverUrl, @HiveField(11)  int? durationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackItem() when $default != null:
return $default(_that.id,_that.url,_that.title,_that.isVideo,_that.source,_that.scopeId,_that.workId,_that.albumTitle,_that.artist,_that.coverUrl,_that.smallCoverUrl,_that.durationMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String url, @HiveField(2)  String title, @HiveField(3)  bool isVideo, @HiveField(4)  NodeSource source, @HiveField(5)  String scopeId, @HiveField(6)  int? workId, @HiveField(7)  String? albumTitle, @HiveField(8)  String? artist, @HiveField(9)  String? coverUrl, @HiveField(10)  String? smallCoverUrl, @HiveField(11)  int? durationMs)  $default,) {final _that = this;
switch (_that) {
case _PlaybackItem():
return $default(_that.id,_that.url,_that.title,_that.isVideo,_that.source,_that.scopeId,_that.workId,_that.albumTitle,_that.artist,_that.coverUrl,_that.smallCoverUrl,_that.durationMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String url, @HiveField(2)  String title, @HiveField(3)  bool isVideo, @HiveField(4)  NodeSource source, @HiveField(5)  String scopeId, @HiveField(6)  int? workId, @HiveField(7)  String? albumTitle, @HiveField(8)  String? artist, @HiveField(9)  String? coverUrl, @HiveField(10)  String? smallCoverUrl, @HiveField(11)  int? durationMs)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackItem() when $default != null:
return $default(_that.id,_that.url,_that.title,_that.isVideo,_that.source,_that.scopeId,_that.workId,_that.albumTitle,_that.artist,_that.coverUrl,_that.smallCoverUrl,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackItem extends PlaybackItem {
  const _PlaybackItem({@HiveField(0) required this.id, @HiveField(1) required this.url, @HiveField(2) required this.title, @HiveField(3) this.isVideo = false, @HiveField(4) this.source = NodeSource.asmrServer, @HiveField(5) required this.scopeId, @HiveField(6) this.workId, @HiveField(7) this.albumTitle, @HiveField(8) this.artist, @HiveField(9) this.coverUrl, @HiveField(10) this.smallCoverUrl, @HiveField(11) this.durationMs}): super._();
  

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String url;
@override@HiveField(2) final  String title;
@override@JsonKey()@HiveField(3) final  bool isVideo;
@override@JsonKey()@HiveField(4) final  NodeSource source;
/// Historical aggregation id.
///
/// Tracks in the same network work or local work share a scopeId. Local
/// singles usually use their own item id as the scopeId.
@override@HiveField(5) final  String scopeId;
@override@HiveField(6) final  int? workId;
@override@HiveField(7) final  String? albumTitle;
@override@HiveField(8) final  String? artist;
@override@HiveField(9) final  String? coverUrl;
@override@HiveField(10) final  String? smallCoverUrl;
@override@HiveField(11) final  int? durationMs;

/// Create a copy of PlaybackItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackItemCopyWith<_PlaybackItem> get copyWith => __$PlaybackItemCopyWithImpl<_PlaybackItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackItem&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.isVideo, isVideo) || other.isVideo == isVideo)&&(identical(other.source, source) || other.source == source)&&(identical(other.scopeId, scopeId) || other.scopeId == scopeId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.albumTitle, albumTitle) || other.albumTitle == albumTitle)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.smallCoverUrl, smallCoverUrl) || other.smallCoverUrl == smallCoverUrl)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,title,isVideo,source,scopeId,workId,albumTitle,artist,coverUrl,smallCoverUrl,durationMs);

@override
String toString() {
  return 'PlaybackItem(id: $id, url: $url, title: $title, isVideo: $isVideo, source: $source, scopeId: $scopeId, workId: $workId, albumTitle: $albumTitle, artist: $artist, coverUrl: $coverUrl, smallCoverUrl: $smallCoverUrl, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$PlaybackItemCopyWith<$Res> implements $PlaybackItemCopyWith<$Res> {
  factory _$PlaybackItemCopyWith(_PlaybackItem value, $Res Function(_PlaybackItem) _then) = __$PlaybackItemCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String url,@HiveField(2) String title,@HiveField(3) bool isVideo,@HiveField(4) NodeSource source,@HiveField(5) String scopeId,@HiveField(6) int? workId,@HiveField(7) String? albumTitle,@HiveField(8) String? artist,@HiveField(9) String? coverUrl,@HiveField(10) String? smallCoverUrl,@HiveField(11) int? durationMs
});




}
/// @nodoc
class __$PlaybackItemCopyWithImpl<$Res>
    implements _$PlaybackItemCopyWith<$Res> {
  __$PlaybackItemCopyWithImpl(this._self, this._then);

  final _PlaybackItem _self;
  final $Res Function(_PlaybackItem) _then;

/// Create a copy of PlaybackItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? title = null,Object? isVideo = null,Object? source = null,Object? scopeId = null,Object? workId = freezed,Object? albumTitle = freezed,Object? artist = freezed,Object? coverUrl = freezed,Object? smallCoverUrl = freezed,Object? durationMs = freezed,}) {
  return _then(_PlaybackItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,isVideo: null == isVideo ? _self.isVideo : isVideo // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NodeSource,scopeId: null == scopeId ? _self.scopeId : scopeId // ignore: cast_nullable_to_non_nullable
as String,workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as int?,albumTitle: freezed == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,smallCoverUrl: freezed == smallCoverUrl ? _self.smallCoverUrl : smallCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$PlaybackSession {

@HiveField(0) String get id;@HiveField(1) int get currentIndex;@HiveField(2) List<PlaybackItem> get queue;@HiveField(3) int get createdAt;@HiveField(4) int get updatedAt;
/// Create a copy of PlaybackSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackSessionCopyWith<PlaybackSession> get copyWith => _$PlaybackSessionCopyWithImpl<PlaybackSession>(this as PlaybackSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackSession&&(identical(other.id, id) || other.id == id)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&const DeepCollectionEquality().equals(other.queue, queue)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,currentIndex,const DeepCollectionEquality().hash(queue),createdAt,updatedAt);

@override
String toString() {
  return 'PlaybackSession(id: $id, currentIndex: $currentIndex, queue: $queue, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlaybackSessionCopyWith<$Res>  {
  factory $PlaybackSessionCopyWith(PlaybackSession value, $Res Function(PlaybackSession) _then) = _$PlaybackSessionCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) int currentIndex,@HiveField(2) List<PlaybackItem> queue,@HiveField(3) int createdAt,@HiveField(4) int updatedAt
});




}
/// @nodoc
class _$PlaybackSessionCopyWithImpl<$Res>
    implements $PlaybackSessionCopyWith<$Res> {
  _$PlaybackSessionCopyWithImpl(this._self, this._then);

  final PlaybackSession _self;
  final $Res Function(PlaybackSession) _then;

/// Create a copy of PlaybackSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? currentIndex = null,Object? queue = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackItem>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackSession].
extension PlaybackSessionPatterns on PlaybackSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackSession value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackSession value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  int currentIndex, @HiveField(2)  List<PlaybackItem> queue, @HiveField(3)  int createdAt, @HiveField(4)  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackSession() when $default != null:
return $default(_that.id,_that.currentIndex,_that.queue,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  int currentIndex, @HiveField(2)  List<PlaybackItem> queue, @HiveField(3)  int createdAt, @HiveField(4)  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlaybackSession():
return $default(_that.id,_that.currentIndex,_that.queue,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  int currentIndex, @HiveField(2)  List<PlaybackItem> queue, @HiveField(3)  int createdAt, @HiveField(4)  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackSession() when $default != null:
return $default(_that.id,_that.currentIndex,_that.queue,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackSession extends PlaybackSession {
  const _PlaybackSession({@HiveField(0) required this.id, @HiveField(1) this.currentIndex = 0, @HiveField(2) final  List<PlaybackItem> queue = const [], @HiveField(3) required this.createdAt, @HiveField(4) required this.updatedAt}): _queue = queue,super._();
  

@override@HiveField(0) final  String id;
@override@JsonKey()@HiveField(1) final  int currentIndex;
 final  List<PlaybackItem> _queue;
@override@JsonKey()@HiveField(2) List<PlaybackItem> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

@override@HiveField(3) final  int createdAt;
@override@HiveField(4) final  int updatedAt;

/// Create a copy of PlaybackSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackSessionCopyWith<_PlaybackSession> get copyWith => __$PlaybackSessionCopyWithImpl<_PlaybackSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackSession&&(identical(other.id, id) || other.id == id)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&const DeepCollectionEquality().equals(other._queue, _queue)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,currentIndex,const DeepCollectionEquality().hash(_queue),createdAt,updatedAt);

@override
String toString() {
  return 'PlaybackSession(id: $id, currentIndex: $currentIndex, queue: $queue, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlaybackSessionCopyWith<$Res> implements $PlaybackSessionCopyWith<$Res> {
  factory _$PlaybackSessionCopyWith(_PlaybackSession value, $Res Function(_PlaybackSession) _then) = __$PlaybackSessionCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) int currentIndex,@HiveField(2) List<PlaybackItem> queue,@HiveField(3) int createdAt,@HiveField(4) int updatedAt
});




}
/// @nodoc
class __$PlaybackSessionCopyWithImpl<$Res>
    implements _$PlaybackSessionCopyWith<$Res> {
  __$PlaybackSessionCopyWithImpl(this._self, this._then);

  final _PlaybackSession _self;
  final $Res Function(_PlaybackSession) _then;

/// Create a copy of PlaybackSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? currentIndex = null,Object? queue = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PlaybackSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackItem>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
