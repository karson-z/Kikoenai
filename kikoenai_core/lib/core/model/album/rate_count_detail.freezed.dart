// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rate_count_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RateCountDetail {

@HiveField(0)@JsonKey(name: 'review_point') int get reviewPoint;@HiveField(1) int get count;@HiveField(2) int get ratio;
/// Create a copy of RateCountDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateCountDetailCopyWith<RateCountDetail> get copyWith => _$RateCountDetailCopyWithImpl<RateCountDetail>(this as RateCountDetail, _$identity);

  /// Serializes this RateCountDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RateCountDetail&&(identical(other.reviewPoint, reviewPoint) || other.reviewPoint == reviewPoint)&&(identical(other.count, count) || other.count == count)&&(identical(other.ratio, ratio) || other.ratio == ratio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewPoint,count,ratio);

@override
String toString() {
  return 'RateCountDetail(reviewPoint: $reviewPoint, count: $count, ratio: $ratio)';
}


}

/// @nodoc
abstract mixin class $RateCountDetailCopyWith<$Res>  {
  factory $RateCountDetailCopyWith(RateCountDetail value, $Res Function(RateCountDetail) _then) = _$RateCountDetailCopyWithImpl;
@useResult
$Res call({
@HiveField(0)@JsonKey(name: 'review_point') int reviewPoint,@HiveField(1) int count,@HiveField(2) int ratio
});




}
/// @nodoc
class _$RateCountDetailCopyWithImpl<$Res>
    implements $RateCountDetailCopyWith<$Res> {
  _$RateCountDetailCopyWithImpl(this._self, this._then);

  final RateCountDetail _self;
  final $Res Function(RateCountDetail) _then;

/// Create a copy of RateCountDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviewPoint = null,Object? count = null,Object? ratio = null,}) {
  return _then(_self.copyWith(
reviewPoint: null == reviewPoint ? _self.reviewPoint : reviewPoint // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,ratio: null == ratio ? _self.ratio : ratio // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RateCountDetail].
extension RateCountDetailPatterns on RateCountDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RateCountDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RateCountDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RateCountDetail value)  $default,){
final _that = this;
switch (_that) {
case _RateCountDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RateCountDetail value)?  $default,){
final _that = this;
switch (_that) {
case _RateCountDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)@JsonKey(name: 'review_point')  int reviewPoint, @HiveField(1)  int count, @HiveField(2)  int ratio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RateCountDetail() when $default != null:
return $default(_that.reviewPoint,_that.count,_that.ratio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)@JsonKey(name: 'review_point')  int reviewPoint, @HiveField(1)  int count, @HiveField(2)  int ratio)  $default,) {final _that = this;
switch (_that) {
case _RateCountDetail():
return $default(_that.reviewPoint,_that.count,_that.ratio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)@JsonKey(name: 'review_point')  int reviewPoint, @HiveField(1)  int count, @HiveField(2)  int ratio)?  $default,) {final _that = this;
switch (_that) {
case _RateCountDetail() when $default != null:
return $default(_that.reviewPoint,_that.count,_that.ratio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RateCountDetail implements RateCountDetail {
  const _RateCountDetail({@HiveField(0)@JsonKey(name: 'review_point') required this.reviewPoint, @HiveField(1) required this.count, @HiveField(2) required this.ratio});
  factory _RateCountDetail.fromJson(Map<String, dynamic> json) => _$RateCountDetailFromJson(json);

@override@HiveField(0)@JsonKey(name: 'review_point') final  int reviewPoint;
@override@HiveField(1) final  int count;
@override@HiveField(2) final  int ratio;

/// Create a copy of RateCountDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RateCountDetailCopyWith<_RateCountDetail> get copyWith => __$RateCountDetailCopyWithImpl<_RateCountDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RateCountDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RateCountDetail&&(identical(other.reviewPoint, reviewPoint) || other.reviewPoint == reviewPoint)&&(identical(other.count, count) || other.count == count)&&(identical(other.ratio, ratio) || other.ratio == ratio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewPoint,count,ratio);

@override
String toString() {
  return 'RateCountDetail(reviewPoint: $reviewPoint, count: $count, ratio: $ratio)';
}


}

/// @nodoc
abstract mixin class _$RateCountDetailCopyWith<$Res> implements $RateCountDetailCopyWith<$Res> {
  factory _$RateCountDetailCopyWith(_RateCountDetail value, $Res Function(_RateCountDetail) _then) = __$RateCountDetailCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0)@JsonKey(name: 'review_point') int reviewPoint,@HiveField(1) int count,@HiveField(2) int ratio
});




}
/// @nodoc
class __$RateCountDetailCopyWithImpl<$Res>
    implements _$RateCountDetailCopyWith<$Res> {
  __$RateCountDetailCopyWithImpl(this._self, this._then);

  final _RateCountDetail _self;
  final $Res Function(_RateCountDetail) _then;

/// Create a copy of RateCountDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewPoint = null,Object? count = null,Object? ratio = null,}) {
  return _then(_RateCountDetail(
reviewPoint: null == reviewPoint ? _self.reviewPoint : reviewPoint // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,ratio: null == ratio ? _self.ratio : ratio // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
