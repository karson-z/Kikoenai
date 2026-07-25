// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'va.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VA {

@HiveField(0) String? get id;@HiveField(1) String? get name;@HiveField(2) int? get count;
/// Create a copy of VA
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VACopyWith<VA> get copyWith => _$VACopyWithImpl<VA>(this as VA, _$identity);

  /// Serializes this VA to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VA&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,count);

@override
String toString() {
  return 'VA(id: $id, name: $name, count: $count)';
}


}

/// @nodoc
abstract mixin class $VACopyWith<$Res>  {
  factory $VACopyWith(VA value, $Res Function(VA) _then) = _$VACopyWithImpl;
@useResult
$Res call({
@HiveField(0) String? id,@HiveField(1) String? name,@HiveField(2) int? count
});




}
/// @nodoc
class _$VACopyWithImpl<$Res>
    implements $VACopyWith<$Res> {
  _$VACopyWithImpl(this._self, this._then);

  final VA _self;
  final $Res Function(VA) _then;

/// Create a copy of VA
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? count = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [VA].
extension VAPatterns on VA {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VA value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VA() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VA value)  $default,){
final _that = this;
switch (_that) {
case _VA():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VA value)?  $default,){
final _that = this;
switch (_that) {
case _VA() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String? id, @HiveField(1)  String? name, @HiveField(2)  int? count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VA() when $default != null:
return $default(_that.id,_that.name,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String? id, @HiveField(1)  String? name, @HiveField(2)  int? count)  $default,) {final _that = this;
switch (_that) {
case _VA():
return $default(_that.id,_that.name,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String? id, @HiveField(1)  String? name, @HiveField(2)  int? count)?  $default,) {final _that = this;
switch (_that) {
case _VA() when $default != null:
return $default(_that.id,_that.name,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VA implements VA {
  const _VA({@HiveField(0) this.id, @HiveField(1) this.name, @HiveField(2) this.count});
  factory _VA.fromJson(Map<String, dynamic> json) => _$VAFromJson(json);

@override@HiveField(0) final  String? id;
@override@HiveField(1) final  String? name;
@override@HiveField(2) final  int? count;

/// Create a copy of VA
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VACopyWith<_VA> get copyWith => __$VACopyWithImpl<_VA>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VAToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VA&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,count);

@override
String toString() {
  return 'VA(id: $id, name: $name, count: $count)';
}


}

/// @nodoc
abstract mixin class _$VACopyWith<$Res> implements $VACopyWith<$Res> {
  factory _$VACopyWith(_VA value, $Res Function(_VA) _then) = __$VACopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String? id,@HiveField(1) String? name,@HiveField(2) int? count
});




}
/// @nodoc
class __$VACopyWithImpl<$Res>
    implements _$VACopyWith<$Res> {
  __$VACopyWithImpl(this._self, this._then);

  final _VA _self;
  final $Res Function(_VA) _then;

/// Create a copy of VA
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? count = freezed,}) {
  return _then(_VA(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
