// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchFilterState {

 bool get isFilterOpen; int get selectedFilterIndex; String get localSearchKeyword;// @HiveField(0)
 String? get keyword;// @HiveField(1)
 List<SearchTag> get selectedTags;// @HiveField(2)
 SortOrder get sortOption;// @HiveField(3)
 SortDirection get sortDirection;// @HiveField(4)
 int get subtitleFilter;
/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<SearchFilterState> get copyWith => _$SearchFilterStateCopyWithImpl<SearchFilterState>(this as SearchFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFilterState&&(identical(other.isFilterOpen, isFilterOpen) || other.isFilterOpen == isFilterOpen)&&(identical(other.selectedFilterIndex, selectedFilterIndex) || other.selectedFilterIndex == selectedFilterIndex)&&(identical(other.localSearchKeyword, localSearchKeyword) || other.localSearchKeyword == localSearchKeyword)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&const DeepCollectionEquality().equals(other.selectedTags, selectedTags)&&(identical(other.sortOption, sortOption) || other.sortOption == sortOption)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection)&&(identical(other.subtitleFilter, subtitleFilter) || other.subtitleFilter == subtitleFilter));
}


@override
int get hashCode => Object.hash(runtimeType,isFilterOpen,selectedFilterIndex,localSearchKeyword,keyword,const DeepCollectionEquality().hash(selectedTags),sortOption,sortDirection,subtitleFilter);

@override
String toString() {
  return 'SearchFilterState(isFilterOpen: $isFilterOpen, selectedFilterIndex: $selectedFilterIndex, localSearchKeyword: $localSearchKeyword, keyword: $keyword, selectedTags: $selectedTags, sortOption: $sortOption, sortDirection: $sortDirection, subtitleFilter: $subtitleFilter)';
}


}

/// @nodoc
abstract mixin class $SearchFilterStateCopyWith<$Res>  {
  factory $SearchFilterStateCopyWith(SearchFilterState value, $Res Function(SearchFilterState) _then) = _$SearchFilterStateCopyWithImpl;
@useResult
$Res call({
 bool isFilterOpen, int selectedFilterIndex, String localSearchKeyword, String? keyword, List<SearchTag> selectedTags, SortOrder sortOption, SortDirection sortDirection, int subtitleFilter
});




}
/// @nodoc
class _$SearchFilterStateCopyWithImpl<$Res>
    implements $SearchFilterStateCopyWith<$Res> {
  _$SearchFilterStateCopyWithImpl(this._self, this._then);

  final SearchFilterState _self;
  final $Res Function(SearchFilterState) _then;

/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isFilterOpen = null,Object? selectedFilterIndex = null,Object? localSearchKeyword = null,Object? keyword = freezed,Object? selectedTags = null,Object? sortOption = null,Object? sortDirection = null,Object? subtitleFilter = null,}) {
  return _then(_self.copyWith(
isFilterOpen: null == isFilterOpen ? _self.isFilterOpen : isFilterOpen // ignore: cast_nullable_to_non_nullable
as bool,selectedFilterIndex: null == selectedFilterIndex ? _self.selectedFilterIndex : selectedFilterIndex // ignore: cast_nullable_to_non_nullable
as int,localSearchKeyword: null == localSearchKeyword ? _self.localSearchKeyword : localSearchKeyword // ignore: cast_nullable_to_non_nullable
as String,keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,selectedTags: null == selectedTags ? _self.selectedTags : selectedTags // ignore: cast_nullable_to_non_nullable
as List<SearchTag>,sortOption: null == sortOption ? _self.sortOption : sortOption // ignore: cast_nullable_to_non_nullable
as SortOrder,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,subtitleFilter: null == subtitleFilter ? _self.subtitleFilter : subtitleFilter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFilterState].
extension SearchFilterStatePatterns on SearchFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFilterState value)  $default,){
final _that = this;
switch (_that) {
case _SearchFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isFilterOpen,  int selectedFilterIndex,  String localSearchKeyword,  String? keyword,  List<SearchTag> selectedTags,  SortOrder sortOption,  SortDirection sortDirection,  int subtitleFilter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
return $default(_that.isFilterOpen,_that.selectedFilterIndex,_that.localSearchKeyword,_that.keyword,_that.selectedTags,_that.sortOption,_that.sortDirection,_that.subtitleFilter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isFilterOpen,  int selectedFilterIndex,  String localSearchKeyword,  String? keyword,  List<SearchTag> selectedTags,  SortOrder sortOption,  SortDirection sortDirection,  int subtitleFilter)  $default,) {final _that = this;
switch (_that) {
case _SearchFilterState():
return $default(_that.isFilterOpen,_that.selectedFilterIndex,_that.localSearchKeyword,_that.keyword,_that.selectedTags,_that.sortOption,_that.sortDirection,_that.subtitleFilter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isFilterOpen,  int selectedFilterIndex,  String localSearchKeyword,  String? keyword,  List<SearchTag> selectedTags,  SortOrder sortOption,  SortDirection sortDirection,  int subtitleFilter)?  $default,) {final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
return $default(_that.isFilterOpen,_that.selectedFilterIndex,_that.localSearchKeyword,_that.keyword,_that.selectedTags,_that.sortOption,_that.sortDirection,_that.subtitleFilter);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFilterState implements SearchFilterState {
  const _SearchFilterState({this.isFilterOpen = false, this.selectedFilterIndex = 0, this.localSearchKeyword = "", this.keyword, final  List<SearchTag> selectedTags = const [], this.sortOption = SortOrder.createDate, this.sortDirection = SortDirection.desc, this.subtitleFilter = 0}): _selectedTags = selectedTags;
  

@override@JsonKey() final  bool isFilterOpen;
@override@JsonKey() final  int selectedFilterIndex;
@override@JsonKey() final  String localSearchKeyword;
// @HiveField(0)
@override final  String? keyword;
// @HiveField(1)
 final  List<SearchTag> _selectedTags;
// @HiveField(1)
@override@JsonKey() List<SearchTag> get selectedTags {
  if (_selectedTags is EqualUnmodifiableListView) return _selectedTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedTags);
}

// @HiveField(2)
@override@JsonKey() final  SortOrder sortOption;
// @HiveField(3)
@override@JsonKey() final  SortDirection sortDirection;
// @HiveField(4)
@override@JsonKey() final  int subtitleFilter;

/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFilterStateCopyWith<_SearchFilterState> get copyWith => __$SearchFilterStateCopyWithImpl<_SearchFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFilterState&&(identical(other.isFilterOpen, isFilterOpen) || other.isFilterOpen == isFilterOpen)&&(identical(other.selectedFilterIndex, selectedFilterIndex) || other.selectedFilterIndex == selectedFilterIndex)&&(identical(other.localSearchKeyword, localSearchKeyword) || other.localSearchKeyword == localSearchKeyword)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&const DeepCollectionEquality().equals(other._selectedTags, _selectedTags)&&(identical(other.sortOption, sortOption) || other.sortOption == sortOption)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection)&&(identical(other.subtitleFilter, subtitleFilter) || other.subtitleFilter == subtitleFilter));
}


@override
int get hashCode => Object.hash(runtimeType,isFilterOpen,selectedFilterIndex,localSearchKeyword,keyword,const DeepCollectionEquality().hash(_selectedTags),sortOption,sortDirection,subtitleFilter);

@override
String toString() {
  return 'SearchFilterState(isFilterOpen: $isFilterOpen, selectedFilterIndex: $selectedFilterIndex, localSearchKeyword: $localSearchKeyword, keyword: $keyword, selectedTags: $selectedTags, sortOption: $sortOption, sortDirection: $sortDirection, subtitleFilter: $subtitleFilter)';
}


}

/// @nodoc
abstract mixin class _$SearchFilterStateCopyWith<$Res> implements $SearchFilterStateCopyWith<$Res> {
  factory _$SearchFilterStateCopyWith(_SearchFilterState value, $Res Function(_SearchFilterState) _then) = __$SearchFilterStateCopyWithImpl;
@override @useResult
$Res call({
 bool isFilterOpen, int selectedFilterIndex, String localSearchKeyword, String? keyword, List<SearchTag> selectedTags, SortOrder sortOption, SortDirection sortDirection, int subtitleFilter
});




}
/// @nodoc
class __$SearchFilterStateCopyWithImpl<$Res>
    implements _$SearchFilterStateCopyWith<$Res> {
  __$SearchFilterStateCopyWithImpl(this._self, this._then);

  final _SearchFilterState _self;
  final $Res Function(_SearchFilterState) _then;

/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isFilterOpen = null,Object? selectedFilterIndex = null,Object? localSearchKeyword = null,Object? keyword = freezed,Object? selectedTags = null,Object? sortOption = null,Object? sortDirection = null,Object? subtitleFilter = null,}) {
  return _then(_SearchFilterState(
isFilterOpen: null == isFilterOpen ? _self.isFilterOpen : isFilterOpen // ignore: cast_nullable_to_non_nullable
as bool,selectedFilterIndex: null == selectedFilterIndex ? _self.selectedFilterIndex : selectedFilterIndex // ignore: cast_nullable_to_non_nullable
as int,localSearchKeyword: null == localSearchKeyword ? _self.localSearchKeyword : localSearchKeyword // ignore: cast_nullable_to_non_nullable
as String,keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,selectedTags: null == selectedTags ? _self._selectedTags : selectedTags // ignore: cast_nullable_to_non_nullable
as List<SearchTag>,sortOption: null == sortOption ? _self.sortOption : sortOption // ignore: cast_nullable_to_non_nullable
as SortOrder,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,subtitleFilter: null == subtitleFilter ? _self.subtitleFilter : subtitleFilter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
