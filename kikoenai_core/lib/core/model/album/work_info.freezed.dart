// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkInfo {

@HiveField(0) int get id;@HiveField(1)@JsonKey(name: 'source_type') String? get sourceType;@HiveField(2)@JsonKey(name: 'source_id') String? get sourceId;
/// Create a copy of WorkInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkInfoCopyWith<WorkInfo> get copyWith => _$WorkInfoCopyWithImpl<WorkInfo>(this as WorkInfo, _$identity);

  /// Serializes this WorkInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourceType,sourceId);

@override
String toString() {
  return 'WorkInfo(id: $id, sourceType: $sourceType, sourceId: $sourceId)';
}


}

/// @nodoc
abstract mixin class $WorkInfoCopyWith<$Res>  {
  factory $WorkInfoCopyWith(WorkInfo value, $Res Function(WorkInfo) _then) = _$WorkInfoCopyWithImpl;
@useResult
$Res call({
@HiveField(0) int id,@HiveField(1)@JsonKey(name: 'source_type') String? sourceType,@HiveField(2)@JsonKey(name: 'source_id') String? sourceId
});




}
/// @nodoc
class _$WorkInfoCopyWithImpl<$Res>
    implements $WorkInfoCopyWith<$Res> {
  _$WorkInfoCopyWithImpl(this._self, this._then);

  final WorkInfo _self;
  final $Res Function(WorkInfo) _then;

/// Create a copy of WorkInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceType = freezed,Object? sourceId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkInfo].
extension WorkInfoPatterns on WorkInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkInfo value)  $default,){
final _that = this;
switch (_that) {
case _WorkInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkInfo value)?  $default,){
final _that = this;
switch (_that) {
case _WorkInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  int id, @HiveField(1)@JsonKey(name: 'source_type')  String? sourceType, @HiveField(2)@JsonKey(name: 'source_id')  String? sourceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkInfo() when $default != null:
return $default(_that.id,_that.sourceType,_that.sourceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  int id, @HiveField(1)@JsonKey(name: 'source_type')  String? sourceType, @HiveField(2)@JsonKey(name: 'source_id')  String? sourceId)  $default,) {final _that = this;
switch (_that) {
case _WorkInfo():
return $default(_that.id,_that.sourceType,_that.sourceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  int id, @HiveField(1)@JsonKey(name: 'source_type')  String? sourceType, @HiveField(2)@JsonKey(name: 'source_id')  String? sourceId)?  $default,) {final _that = this;
switch (_that) {
case _WorkInfo() when $default != null:
return $default(_that.id,_that.sourceType,_that.sourceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkInfo implements WorkInfo {
  const _WorkInfo({@HiveField(0) required this.id, @HiveField(1)@JsonKey(name: 'source_type') this.sourceType, @HiveField(2)@JsonKey(name: 'source_id') this.sourceId});
  factory _WorkInfo.fromJson(Map<String, dynamic> json) => _$WorkInfoFromJson(json);

@override@HiveField(0) final  int id;
@override@HiveField(1)@JsonKey(name: 'source_type') final  String? sourceType;
@override@HiveField(2)@JsonKey(name: 'source_id') final  String? sourceId;

/// Create a copy of WorkInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkInfoCopyWith<_WorkInfo> get copyWith => __$WorkInfoCopyWithImpl<_WorkInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourceType,sourceId);

@override
String toString() {
  return 'WorkInfo(id: $id, sourceType: $sourceType, sourceId: $sourceId)';
}


}

/// @nodoc
abstract mixin class _$WorkInfoCopyWith<$Res> implements $WorkInfoCopyWith<$Res> {
  factory _$WorkInfoCopyWith(_WorkInfo value, $Res Function(_WorkInfo) _then) = __$WorkInfoCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) int id,@HiveField(1)@JsonKey(name: 'source_type') String? sourceType,@HiveField(2)@JsonKey(name: 'source_id') String? sourceId
});




}
/// @nodoc
class __$WorkInfoCopyWithImpl<$Res>
    implements _$WorkInfoCopyWith<$Res> {
  __$WorkInfoCopyWithImpl(this._self, this._then);

  final _WorkInfo _self;
  final $Res Function(_WorkInfo) _then;

/// Create a copy of WorkInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceType = freezed,Object? sourceId = freezed,}) {
  return _then(_WorkInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
