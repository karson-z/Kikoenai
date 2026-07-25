// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'other_language_edition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtherLanguageEdition {

@HiveField(0) int? get id;@HiveField(1) String? get lang;@HiveField(2) String? get title;@HiveField(3)@JsonKey(name: 'source_id') String? get sourceId;@HiveField(4)@JsonKey(name: 'is_original') bool? get isOriginal;@HiveField(5)@JsonKey(name: 'source_type') String? get sourceType;
/// Create a copy of OtherLanguageEdition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtherLanguageEditionCopyWith<OtherLanguageEdition> get copyWith => _$OtherLanguageEditionCopyWithImpl<OtherLanguageEdition>(this as OtherLanguageEdition, _$identity);

  /// Serializes this OtherLanguageEdition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtherLanguageEdition&&(identical(other.id, id) || other.id == id)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.isOriginal, isOriginal) || other.isOriginal == isOriginal)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lang,title,sourceId,isOriginal,sourceType);

@override
String toString() {
  return 'OtherLanguageEdition(id: $id, lang: $lang, title: $title, sourceId: $sourceId, isOriginal: $isOriginal, sourceType: $sourceType)';
}


}

/// @nodoc
abstract mixin class $OtherLanguageEditionCopyWith<$Res>  {
  factory $OtherLanguageEditionCopyWith(OtherLanguageEdition value, $Res Function(OtherLanguageEdition) _then) = _$OtherLanguageEditionCopyWithImpl;
@useResult
$Res call({
@HiveField(0) int? id,@HiveField(1) String? lang,@HiveField(2) String? title,@HiveField(3)@JsonKey(name: 'source_id') String? sourceId,@HiveField(4)@JsonKey(name: 'is_original') bool? isOriginal,@HiveField(5)@JsonKey(name: 'source_type') String? sourceType
});




}
/// @nodoc
class _$OtherLanguageEditionCopyWithImpl<$Res>
    implements $OtherLanguageEditionCopyWith<$Res> {
  _$OtherLanguageEditionCopyWithImpl(this._self, this._then);

  final OtherLanguageEdition _self;
  final $Res Function(OtherLanguageEdition) _then;

/// Create a copy of OtherLanguageEdition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? lang = freezed,Object? title = freezed,Object? sourceId = freezed,Object? isOriginal = freezed,Object? sourceType = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,isOriginal: freezed == isOriginal ? _self.isOriginal : isOriginal // ignore: cast_nullable_to_non_nullable
as bool?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtherLanguageEdition].
extension OtherLanguageEditionPatterns on OtherLanguageEdition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtherLanguageEdition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtherLanguageEdition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtherLanguageEdition value)  $default,){
final _that = this;
switch (_that) {
case _OtherLanguageEdition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtherLanguageEdition value)?  $default,){
final _that = this;
switch (_that) {
case _OtherLanguageEdition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  int? id, @HiveField(1)  String? lang, @HiveField(2)  String? title, @HiveField(3)@JsonKey(name: 'source_id')  String? sourceId, @HiveField(4)@JsonKey(name: 'is_original')  bool? isOriginal, @HiveField(5)@JsonKey(name: 'source_type')  String? sourceType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtherLanguageEdition() when $default != null:
return $default(_that.id,_that.lang,_that.title,_that.sourceId,_that.isOriginal,_that.sourceType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  int? id, @HiveField(1)  String? lang, @HiveField(2)  String? title, @HiveField(3)@JsonKey(name: 'source_id')  String? sourceId, @HiveField(4)@JsonKey(name: 'is_original')  bool? isOriginal, @HiveField(5)@JsonKey(name: 'source_type')  String? sourceType)  $default,) {final _that = this;
switch (_that) {
case _OtherLanguageEdition():
return $default(_that.id,_that.lang,_that.title,_that.sourceId,_that.isOriginal,_that.sourceType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  int? id, @HiveField(1)  String? lang, @HiveField(2)  String? title, @HiveField(3)@JsonKey(name: 'source_id')  String? sourceId, @HiveField(4)@JsonKey(name: 'is_original')  bool? isOriginal, @HiveField(5)@JsonKey(name: 'source_type')  String? sourceType)?  $default,) {final _that = this;
switch (_that) {
case _OtherLanguageEdition() when $default != null:
return $default(_that.id,_that.lang,_that.title,_that.sourceId,_that.isOriginal,_that.sourceType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtherLanguageEdition implements OtherLanguageEdition {
  const _OtherLanguageEdition({@HiveField(0) this.id, @HiveField(1) this.lang, @HiveField(2) this.title, @HiveField(3)@JsonKey(name: 'source_id') this.sourceId, @HiveField(4)@JsonKey(name: 'is_original') this.isOriginal, @HiveField(5)@JsonKey(name: 'source_type') this.sourceType});
  factory _OtherLanguageEdition.fromJson(Map<String, dynamic> json) => _$OtherLanguageEditionFromJson(json);

@override@HiveField(0) final  int? id;
@override@HiveField(1) final  String? lang;
@override@HiveField(2) final  String? title;
@override@HiveField(3)@JsonKey(name: 'source_id') final  String? sourceId;
@override@HiveField(4)@JsonKey(name: 'is_original') final  bool? isOriginal;
@override@HiveField(5)@JsonKey(name: 'source_type') final  String? sourceType;

/// Create a copy of OtherLanguageEdition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtherLanguageEditionCopyWith<_OtherLanguageEdition> get copyWith => __$OtherLanguageEditionCopyWithImpl<_OtherLanguageEdition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtherLanguageEditionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtherLanguageEdition&&(identical(other.id, id) || other.id == id)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.isOriginal, isOriginal) || other.isOriginal == isOriginal)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lang,title,sourceId,isOriginal,sourceType);

@override
String toString() {
  return 'OtherLanguageEdition(id: $id, lang: $lang, title: $title, sourceId: $sourceId, isOriginal: $isOriginal, sourceType: $sourceType)';
}


}

/// @nodoc
abstract mixin class _$OtherLanguageEditionCopyWith<$Res> implements $OtherLanguageEditionCopyWith<$Res> {
  factory _$OtherLanguageEditionCopyWith(_OtherLanguageEdition value, $Res Function(_OtherLanguageEdition) _then) = __$OtherLanguageEditionCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) int? id,@HiveField(1) String? lang,@HiveField(2) String? title,@HiveField(3)@JsonKey(name: 'source_id') String? sourceId,@HiveField(4)@JsonKey(name: 'is_original') bool? isOriginal,@HiveField(5)@JsonKey(name: 'source_type') String? sourceType
});




}
/// @nodoc
class __$OtherLanguageEditionCopyWithImpl<$Res>
    implements _$OtherLanguageEditionCopyWith<$Res> {
  __$OtherLanguageEditionCopyWithImpl(this._self, this._then);

  final _OtherLanguageEdition _self;
  final $Res Function(_OtherLanguageEdition) _then;

/// Create a copy of OtherLanguageEdition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? lang = freezed,Object? title = freezed,Object? sourceId = freezed,Object? isOriginal = freezed,Object? sourceType = freezed,}) {
  return _then(_OtherLanguageEdition(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,isOriginal: freezed == isOriginal ? _self.isOriginal : isOriginal // ignore: cast_nullable_to_non_nullable
as bool?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
