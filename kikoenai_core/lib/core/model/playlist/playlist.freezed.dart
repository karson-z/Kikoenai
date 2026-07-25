// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Playlist {

 String get id;// 修复 1: 加上 @JsonKey 映射 JSON 中的 user_name
// 修复 2: 加默认值，防止 null 导致 crash
@JsonKey(name: 'user_name') String get userName;// 隐私状态，0 通常代表公开
 int get privacy; String get locale;// 修复: 映射 playback_count
@JsonKey(name: 'playback_count') int get playbackCount; String get name; String get description;// 修复 3: 时间字段改为可空 (DateTime?)，并映射 created_at
// 因为解析失败或字段为空时，required DateTime 会直接炸掉
@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;// 修复: 映射 works_count
@JsonKey(name: 'works_count') int get worksCount;// 修复: 映射 latestWorkID (注意 JSON 里的 ID 是大写)
@JsonKey(name: 'latestWorkID') int? get latestWorkId; String? get mainCoverUrl;
/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCopyWith<Playlist> get copyWith => _$PlaylistCopyWithImpl<Playlist>(this as Playlist, _$identity);

  /// Serializes this Playlist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Playlist&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.playbackCount, playbackCount) || other.playbackCount == playbackCount)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.worksCount, worksCount) || other.worksCount == worksCount)&&(identical(other.latestWorkId, latestWorkId) || other.latestWorkId == latestWorkId)&&(identical(other.mainCoverUrl, mainCoverUrl) || other.mainCoverUrl == mainCoverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,privacy,locale,playbackCount,name,description,createdAt,updatedAt,worksCount,latestWorkId,mainCoverUrl);

@override
String toString() {
  return 'Playlist(id: $id, userName: $userName, privacy: $privacy, locale: $locale, playbackCount: $playbackCount, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, worksCount: $worksCount, latestWorkId: $latestWorkId, mainCoverUrl: $mainCoverUrl)';
}


}

/// @nodoc
abstract mixin class $PlaylistCopyWith<$Res>  {
  factory $PlaylistCopyWith(Playlist value, $Res Function(Playlist) _then) = _$PlaylistCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_name') String userName, int privacy, String locale,@JsonKey(name: 'playback_count') int playbackCount, String name, String description,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'works_count') int worksCount,@JsonKey(name: 'latestWorkID') int? latestWorkId, String? mainCoverUrl
});




}
/// @nodoc
class _$PlaylistCopyWithImpl<$Res>
    implements $PlaylistCopyWith<$Res> {
  _$PlaylistCopyWithImpl(this._self, this._then);

  final Playlist _self;
  final $Res Function(Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userName = null,Object? privacy = null,Object? locale = null,Object? playbackCount = null,Object? name = null,Object? description = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? worksCount = null,Object? latestWorkId = freezed,Object? mainCoverUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as int,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,playbackCount: null == playbackCount ? _self.playbackCount : playbackCount // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,worksCount: null == worksCount ? _self.worksCount : worksCount // ignore: cast_nullable_to_non_nullable
as int,latestWorkId: freezed == latestWorkId ? _self.latestWorkId : latestWorkId // ignore: cast_nullable_to_non_nullable
as int?,mainCoverUrl: freezed == mainCoverUrl ? _self.mainCoverUrl : mainCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Playlist].
extension PlaylistPatterns on Playlist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Playlist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Playlist value)  $default,){
final _that = this;
switch (_that) {
case _Playlist():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Playlist value)?  $default,){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_name')  String userName,  int privacy,  String locale, @JsonKey(name: 'playback_count')  int playbackCount,  String name,  String description, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'works_count')  int worksCount, @JsonKey(name: 'latestWorkID')  int? latestWorkId,  String? mainCoverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Playlist() when $default != null:
return $default(_that.id,_that.userName,_that.privacy,_that.locale,_that.playbackCount,_that.name,_that.description,_that.createdAt,_that.updatedAt,_that.worksCount,_that.latestWorkId,_that.mainCoverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_name')  String userName,  int privacy,  String locale, @JsonKey(name: 'playback_count')  int playbackCount,  String name,  String description, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'works_count')  int worksCount, @JsonKey(name: 'latestWorkID')  int? latestWorkId,  String? mainCoverUrl)  $default,) {final _that = this;
switch (_that) {
case _Playlist():
return $default(_that.id,_that.userName,_that.privacy,_that.locale,_that.playbackCount,_that.name,_that.description,_that.createdAt,_that.updatedAt,_that.worksCount,_that.latestWorkId,_that.mainCoverUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_name')  String userName,  int privacy,  String locale, @JsonKey(name: 'playback_count')  int playbackCount,  String name,  String description, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'works_count')  int worksCount, @JsonKey(name: 'latestWorkID')  int? latestWorkId,  String? mainCoverUrl)?  $default,) {final _that = this;
switch (_that) {
case _Playlist() when $default != null:
return $default(_that.id,_that.userName,_that.privacy,_that.locale,_that.playbackCount,_that.name,_that.description,_that.createdAt,_that.updatedAt,_that.worksCount,_that.latestWorkId,_that.mainCoverUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Playlist implements Playlist {
  const _Playlist({required this.id, @JsonKey(name: 'user_name') this.userName = '', this.privacy = 0, this.locale = 'zh-CN', @JsonKey(name: 'playback_count') this.playbackCount = 0, this.name = '', this.description = '', @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'works_count') this.worksCount = 0, @JsonKey(name: 'latestWorkID') this.latestWorkId, this.mainCoverUrl});
  factory _Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

@override final  String id;
// 修复 1: 加上 @JsonKey 映射 JSON 中的 user_name
// 修复 2: 加默认值，防止 null 导致 crash
@override@JsonKey(name: 'user_name') final  String userName;
// 隐私状态，0 通常代表公开
@override@JsonKey() final  int privacy;
@override@JsonKey() final  String locale;
// 修复: 映射 playback_count
@override@JsonKey(name: 'playback_count') final  int playbackCount;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
// 修复 3: 时间字段改为可空 (DateTime?)，并映射 created_at
// 因为解析失败或字段为空时，required DateTime 会直接炸掉
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
// 修复: 映射 works_count
@override@JsonKey(name: 'works_count') final  int worksCount;
// 修复: 映射 latestWorkID (注意 JSON 里的 ID 是大写)
@override@JsonKey(name: 'latestWorkID') final  int? latestWorkId;
@override final  String? mainCoverUrl;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistCopyWith<_Playlist> get copyWith => __$PlaylistCopyWithImpl<_Playlist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Playlist&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.playbackCount, playbackCount) || other.playbackCount == playbackCount)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.worksCount, worksCount) || other.worksCount == worksCount)&&(identical(other.latestWorkId, latestWorkId) || other.latestWorkId == latestWorkId)&&(identical(other.mainCoverUrl, mainCoverUrl) || other.mainCoverUrl == mainCoverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,privacy,locale,playbackCount,name,description,createdAt,updatedAt,worksCount,latestWorkId,mainCoverUrl);

@override
String toString() {
  return 'Playlist(id: $id, userName: $userName, privacy: $privacy, locale: $locale, playbackCount: $playbackCount, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, worksCount: $worksCount, latestWorkId: $latestWorkId, mainCoverUrl: $mainCoverUrl)';
}


}

/// @nodoc
abstract mixin class _$PlaylistCopyWith<$Res> implements $PlaylistCopyWith<$Res> {
  factory _$PlaylistCopyWith(_Playlist value, $Res Function(_Playlist) _then) = __$PlaylistCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_name') String userName, int privacy, String locale,@JsonKey(name: 'playback_count') int playbackCount, String name, String description,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'works_count') int worksCount,@JsonKey(name: 'latestWorkID') int? latestWorkId, String? mainCoverUrl
});




}
/// @nodoc
class __$PlaylistCopyWithImpl<$Res>
    implements _$PlaylistCopyWith<$Res> {
  __$PlaylistCopyWithImpl(this._self, this._then);

  final _Playlist _self;
  final $Res Function(_Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userName = null,Object? privacy = null,Object? locale = null,Object? playbackCount = null,Object? name = null,Object? description = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? worksCount = null,Object? latestWorkId = freezed,Object? mainCoverUrl = freezed,}) {
  return _then(_Playlist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as int,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,playbackCount: null == playbackCount ? _self.playbackCount : playbackCount // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,worksCount: null == worksCount ? _self.worksCount : worksCount // ignore: cast_nullable_to_non_nullable
as int,latestWorkId: freezed == latestWorkId ? _self.latestWorkId : latestWorkId // ignore: cast_nullable_to_non_nullable
as int?,mainCoverUrl: freezed == mainCoverUrl ? _self.mainCoverUrl : mainCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
