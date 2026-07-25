// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkState {

 List<Work> get works; int get currentPage; int get totalCount; bool get hasMore; bool get isLoading;
/// Create a copy of WorkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkStateCopyWith<WorkState> get copyWith => _$WorkStateCopyWithImpl<WorkState>(this as WorkState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkState&&const DeepCollectionEquality().equals(other.works, works)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(works),currentPage,totalCount,hasMore,isLoading);

@override
String toString() {
  return 'WorkState(works: $works, currentPage: $currentPage, totalCount: $totalCount, hasMore: $hasMore, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $WorkStateCopyWith<$Res>  {
  factory $WorkStateCopyWith(WorkState value, $Res Function(WorkState) _then) = _$WorkStateCopyWithImpl;
@useResult
$Res call({
 List<Work> works, int currentPage, int totalCount, bool hasMore, bool isLoading
});




}
/// @nodoc
class _$WorkStateCopyWithImpl<$Res>
    implements $WorkStateCopyWith<$Res> {
  _$WorkStateCopyWithImpl(this._self, this._then);

  final WorkState _self;
  final $Res Function(WorkState) _then;

/// Create a copy of WorkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? works = null,Object? currentPage = null,Object? totalCount = null,Object? hasMore = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
works: null == works ? _self.works : works // ignore: cast_nullable_to_non_nullable
as List<Work>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkState].
extension WorkStatePatterns on WorkState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkState value)  $default,){
final _that = this;
switch (_that) {
case _WorkState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Work> works,  int currentPage,  int totalCount,  bool hasMore,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkState() when $default != null:
return $default(_that.works,_that.currentPage,_that.totalCount,_that.hasMore,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Work> works,  int currentPage,  int totalCount,  bool hasMore,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _WorkState():
return $default(_that.works,_that.currentPage,_that.totalCount,_that.hasMore,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Work> works,  int currentPage,  int totalCount,  bool hasMore,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _WorkState() when $default != null:
return $default(_that.works,_that.currentPage,_that.totalCount,_that.hasMore,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _WorkState implements WorkState {
  const _WorkState({final  List<Work> works = const [], this.currentPage = 1, this.totalCount = 0, this.hasMore = true, this.isLoading = false}): _works = works;
  

 final  List<Work> _works;
@override@JsonKey() List<Work> get works {
  if (_works is EqualUnmodifiableListView) return _works;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_works);
}

@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int totalCount;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool isLoading;

/// Create a copy of WorkState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkStateCopyWith<_WorkState> get copyWith => __$WorkStateCopyWithImpl<_WorkState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkState&&const DeepCollectionEquality().equals(other._works, _works)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_works),currentPage,totalCount,hasMore,isLoading);

@override
String toString() {
  return 'WorkState(works: $works, currentPage: $currentPage, totalCount: $totalCount, hasMore: $hasMore, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$WorkStateCopyWith<$Res> implements $WorkStateCopyWith<$Res> {
  factory _$WorkStateCopyWith(_WorkState value, $Res Function(_WorkState) _then) = __$WorkStateCopyWithImpl;
@override @useResult
$Res call({
 List<Work> works, int currentPage, int totalCount, bool hasMore, bool isLoading
});




}
/// @nodoc
class __$WorkStateCopyWithImpl<$Res>
    implements _$WorkStateCopyWith<$Res> {
  __$WorkStateCopyWithImpl(this._self, this._then);

  final _WorkState _self;
  final $Res Function(_WorkState) _then;

/// Create a copy of WorkState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? works = null,Object? currentPage = null,Object? totalCount = null,Object? hasMore = null,Object? isLoading = null,}) {
  return _then(_WorkState(
works: null == works ? _self._works : works // ignore: cast_nullable_to_non_nullable
as List<Work>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
