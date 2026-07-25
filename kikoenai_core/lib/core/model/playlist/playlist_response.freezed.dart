// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaylistListResponse {

 List<Playlist> get playlists;// 分页信息
 Pagination get pagination;
/// Create a copy of PlaylistListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistListResponseCopyWith<PlaylistListResponse> get copyWith => _$PlaylistListResponseCopyWithImpl<PlaylistListResponse>(this as PlaylistListResponse, _$identity);

  /// Serializes this PlaylistListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistListResponse&&const DeepCollectionEquality().equals(other.playlists, playlists)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(playlists),pagination);

@override
String toString() {
  return 'PlaylistListResponse(playlists: $playlists, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class $PlaylistListResponseCopyWith<$Res>  {
  factory $PlaylistListResponseCopyWith(PlaylistListResponse value, $Res Function(PlaylistListResponse) _then) = _$PlaylistListResponseCopyWithImpl;
@useResult
$Res call({
 List<Playlist> playlists, Pagination pagination
});




}
/// @nodoc
class _$PlaylistListResponseCopyWithImpl<$Res>
    implements $PlaylistListResponseCopyWith<$Res> {
  _$PlaylistListResponseCopyWithImpl(this._self, this._then);

  final PlaylistListResponse _self;
  final $Res Function(PlaylistListResponse) _then;

/// Create a copy of PlaylistListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playlists = null,Object? pagination = null,}) {
  return _then(_self.copyWith(
playlists: null == playlists ? _self.playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistListResponse].
extension PlaylistListResponsePatterns on PlaylistListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistListResponse value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Playlist> playlists,  Pagination pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistListResponse() when $default != null:
return $default(_that.playlists,_that.pagination);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Playlist> playlists,  Pagination pagination)  $default,) {final _that = this;
switch (_that) {
case _PlaylistListResponse():
return $default(_that.playlists,_that.pagination);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Playlist> playlists,  Pagination pagination)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistListResponse() when $default != null:
return $default(_that.playlists,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistListResponse implements PlaylistListResponse {
  const _PlaylistListResponse({final  List<Playlist> playlists = const [], required this.pagination}): _playlists = playlists;
  factory _PlaylistListResponse.fromJson(Map<String, dynamic> json) => _$PlaylistListResponseFromJson(json);

 final  List<Playlist> _playlists;
@override@JsonKey() List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}

// 分页信息
@override final  Pagination pagination;

/// Create a copy of PlaylistListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistListResponseCopyWith<_PlaylistListResponse> get copyWith => __$PlaylistListResponseCopyWithImpl<_PlaylistListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistListResponse&&const DeepCollectionEquality().equals(other._playlists, _playlists)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlists),pagination);

@override
String toString() {
  return 'PlaylistListResponse(playlists: $playlists, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$PlaylistListResponseCopyWith<$Res> implements $PlaylistListResponseCopyWith<$Res> {
  factory _$PlaylistListResponseCopyWith(_PlaylistListResponse value, $Res Function(_PlaylistListResponse) _then) = __$PlaylistListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<Playlist> playlists, Pagination pagination
});




}
/// @nodoc
class __$PlaylistListResponseCopyWithImpl<$Res>
    implements _$PlaylistListResponseCopyWith<$Res> {
  __$PlaylistListResponseCopyWithImpl(this._self, this._then);

  final _PlaylistListResponse _self;
  final $Res Function(_PlaylistListResponse) _then;

/// Create a copy of PlaylistListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playlists = null,Object? pagination = null,}) {
  return _then(_PlaylistListResponse(
playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination,
  ));
}


}

// dart format on
