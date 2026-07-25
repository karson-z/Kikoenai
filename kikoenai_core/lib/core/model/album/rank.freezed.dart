// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rank.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rank {

@HiveField(0) String get term;@HiveField(1) String get category;@HiveField(2) int get rank;@HiveField(3)@JsonKey(name: 'rank_date') String get rankDate;
/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankCopyWith<Rank> get copyWith => _$RankCopyWithImpl<Rank>(this as Rank, _$identity);

  /// Serializes this Rank to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rank&&(identical(other.term, term) || other.term == term)&&(identical(other.category, category) || other.category == category)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.rankDate, rankDate) || other.rankDate == rankDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,category,rank,rankDate);

@override
String toString() {
  return 'Rank(term: $term, category: $category, rank: $rank, rankDate: $rankDate)';
}


}

/// @nodoc
abstract mixin class $RankCopyWith<$Res>  {
  factory $RankCopyWith(Rank value, $Res Function(Rank) _then) = _$RankCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String term,@HiveField(1) String category,@HiveField(2) int rank,@HiveField(3)@JsonKey(name: 'rank_date') String rankDate
});




}
/// @nodoc
class _$RankCopyWithImpl<$Res>
    implements $RankCopyWith<$Res> {
  _$RankCopyWithImpl(this._self, this._then);

  final Rank _self;
  final $Res Function(Rank) _then;

/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = null,Object? category = null,Object? rank = null,Object? rankDate = null,}) {
  return _then(_self.copyWith(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,rankDate: null == rankDate ? _self.rankDate : rankDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Rank].
extension RankPatterns on Rank {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rank value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rank() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rank value)  $default,){
final _that = this;
switch (_that) {
case _Rank():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rank value)?  $default,){
final _that = this;
switch (_that) {
case _Rank() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String term, @HiveField(1)  String category, @HiveField(2)  int rank, @HiveField(3)@JsonKey(name: 'rank_date')  String rankDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rank() when $default != null:
return $default(_that.term,_that.category,_that.rank,_that.rankDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String term, @HiveField(1)  String category, @HiveField(2)  int rank, @HiveField(3)@JsonKey(name: 'rank_date')  String rankDate)  $default,) {final _that = this;
switch (_that) {
case _Rank():
return $default(_that.term,_that.category,_that.rank,_that.rankDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String term, @HiveField(1)  String category, @HiveField(2)  int rank, @HiveField(3)@JsonKey(name: 'rank_date')  String rankDate)?  $default,) {final _that = this;
switch (_that) {
case _Rank() when $default != null:
return $default(_that.term,_that.category,_that.rank,_that.rankDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rank implements Rank {
  const _Rank({@HiveField(0) required this.term, @HiveField(1) required this.category, @HiveField(2) required this.rank, @HiveField(3)@JsonKey(name: 'rank_date') required this.rankDate});
  factory _Rank.fromJson(Map<String, dynamic> json) => _$RankFromJson(json);

@override@HiveField(0) final  String term;
@override@HiveField(1) final  String category;
@override@HiveField(2) final  int rank;
@override@HiveField(3)@JsonKey(name: 'rank_date') final  String rankDate;

/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankCopyWith<_Rank> get copyWith => __$RankCopyWithImpl<_Rank>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rank&&(identical(other.term, term) || other.term == term)&&(identical(other.category, category) || other.category == category)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.rankDate, rankDate) || other.rankDate == rankDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,category,rank,rankDate);

@override
String toString() {
  return 'Rank(term: $term, category: $category, rank: $rank, rankDate: $rankDate)';
}


}

/// @nodoc
abstract mixin class _$RankCopyWith<$Res> implements $RankCopyWith<$Res> {
  factory _$RankCopyWith(_Rank value, $Res Function(_Rank) _then) = __$RankCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String term,@HiveField(1) String category,@HiveField(2) int rank,@HiveField(3)@JsonKey(name: 'rank_date') String rankDate
});




}
/// @nodoc
class __$RankCopyWithImpl<$Res>
    implements _$RankCopyWith<$Res> {
  __$RankCopyWithImpl(this._self, this._then);

  final _Rank _self;
  final $Res Function(_Rank) _then;

/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? category = null,Object? rank = null,Object? rankDate = null,}) {
  return _then(_Rank(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,rankDate: null == rankDate ? _self.rankDate : rankDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
