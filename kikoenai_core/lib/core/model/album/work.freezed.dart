// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Work {

@HiveField(0) int get id;@HiveField(1) String? get title;@HiveField(2)@JsonKey(name: 'circle_id') int? get circleId;@HiveField(3) String? get name;@HiveField(4) bool? get nsfw;@HiveField(5) String? get release;@HiveField(6)@JsonKey(name: 'dl_count') int? get dlCount;@HiveField(7) int? get price;@HiveField(8)@JsonKey(name: 'review_count') int? get reviewCount;@HiveField(9)@JsonKey(name: 'review_text') String? get reviewText;@HiveField(10)@JsonKey(name: 'rate_count') int? get rateCount;@HiveField(11)@JsonKey(name: 'rate_average_2dp') double? get rateAverage2dp;@HiveField(12)@JsonKey(name: 'rate_count_detail') List<RateCountDetail>? get rateCountDetail;@HiveField(13) List<Rank>? get rank;@HiveField(14)@JsonKey(name: 'has_subtitle') bool? get hasSubtitle;@HiveField(15)@JsonKey(name: 'create_date') String? get createDate;@HiveField(16) List<VA>? get vas;@HiveField(17) List<Tag>? get tags;@HiveField(18)@JsonKey(name: 'original_workno') String? get originalWorkno;@HiveField(19)@JsonKey(name: 'other_language_editions_in_db') List<OtherLanguageEdition>? get otherLanguageEditionsInDb;@HiveField(20)@JsonKey(name: 'work_attributes') String? get workAttributes;@HiveField(21)@JsonKey(name: 'age_category_string') String? get ageCategoryString;@HiveField(22) int? get duration;@HiveField(23)@JsonKey(name: 'source_type') String? get sourceType;@HiveField(24)@JsonKey(name: 'source_id') String? get sourceId;@HiveField(25)@JsonKey(name: 'source_url') String? get sourceUrl;@HiveField(26)@JsonKey(name: 'updated_at') String? get updatedAt;@HiveField(27) dynamic get userRating;@HiveField(28) Map<String, bool>? get playlistStatus;@HiveField(29) Circle? get circle;@HiveField(30) String? get samCoverUrl;@HiveField(31) String? get thumbnailCoverUrl;@HiveField(32) String? get mainCoverUrl;@HiveField(33) String? get progress;/// Hero animation unique identifier (excluded from JSON and Hive persistence)
@JsonKey(includeFromJson: false, includeToJson: false) String? get heroTag;
/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkCopyWith<Work> get copyWith => _$WorkCopyWithImpl<Work>(this as Work, _$identity);

  /// Serializes this Work to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Work&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.circleId, circleId) || other.circleId == circleId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nsfw, nsfw) || other.nsfw == nsfw)&&(identical(other.release, release) || other.release == release)&&(identical(other.dlCount, dlCount) || other.dlCount == dlCount)&&(identical(other.price, price) || other.price == price)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.reviewText, reviewText) || other.reviewText == reviewText)&&(identical(other.rateCount, rateCount) || other.rateCount == rateCount)&&(identical(other.rateAverage2dp, rateAverage2dp) || other.rateAverage2dp == rateAverage2dp)&&const DeepCollectionEquality().equals(other.rateCountDetail, rateCountDetail)&&const DeepCollectionEquality().equals(other.rank, rank)&&(identical(other.hasSubtitle, hasSubtitle) || other.hasSubtitle == hasSubtitle)&&(identical(other.createDate, createDate) || other.createDate == createDate)&&const DeepCollectionEquality().equals(other.vas, vas)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.originalWorkno, originalWorkno) || other.originalWorkno == originalWorkno)&&const DeepCollectionEquality().equals(other.otherLanguageEditionsInDb, otherLanguageEditionsInDb)&&(identical(other.workAttributes, workAttributes) || other.workAttributes == workAttributes)&&(identical(other.ageCategoryString, ageCategoryString) || other.ageCategoryString == ageCategoryString)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.userRating, userRating)&&const DeepCollectionEquality().equals(other.playlistStatus, playlistStatus)&&(identical(other.circle, circle) || other.circle == circle)&&(identical(other.samCoverUrl, samCoverUrl) || other.samCoverUrl == samCoverUrl)&&(identical(other.thumbnailCoverUrl, thumbnailCoverUrl) || other.thumbnailCoverUrl == thumbnailCoverUrl)&&(identical(other.mainCoverUrl, mainCoverUrl) || other.mainCoverUrl == mainCoverUrl)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.heroTag, heroTag) || other.heroTag == heroTag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,circleId,name,nsfw,release,dlCount,price,reviewCount,reviewText,rateCount,rateAverage2dp,const DeepCollectionEquality().hash(rateCountDetail),const DeepCollectionEquality().hash(rank),hasSubtitle,createDate,const DeepCollectionEquality().hash(vas),const DeepCollectionEquality().hash(tags),originalWorkno,const DeepCollectionEquality().hash(otherLanguageEditionsInDb),workAttributes,ageCategoryString,duration,sourceType,sourceId,sourceUrl,updatedAt,const DeepCollectionEquality().hash(userRating),const DeepCollectionEquality().hash(playlistStatus),circle,samCoverUrl,thumbnailCoverUrl,mainCoverUrl,progress,heroTag]);

@override
String toString() {
  return 'Work(id: $id, title: $title, circleId: $circleId, name: $name, nsfw: $nsfw, release: $release, dlCount: $dlCount, price: $price, reviewCount: $reviewCount, reviewText: $reviewText, rateCount: $rateCount, rateAverage2dp: $rateAverage2dp, rateCountDetail: $rateCountDetail, rank: $rank, hasSubtitle: $hasSubtitle, createDate: $createDate, vas: $vas, tags: $tags, originalWorkno: $originalWorkno, otherLanguageEditionsInDb: $otherLanguageEditionsInDb, workAttributes: $workAttributes, ageCategoryString: $ageCategoryString, duration: $duration, sourceType: $sourceType, sourceId: $sourceId, sourceUrl: $sourceUrl, updatedAt: $updatedAt, userRating: $userRating, playlistStatus: $playlistStatus, circle: $circle, samCoverUrl: $samCoverUrl, thumbnailCoverUrl: $thumbnailCoverUrl, mainCoverUrl: $mainCoverUrl, progress: $progress, heroTag: $heroTag)';
}


}

/// @nodoc
abstract mixin class $WorkCopyWith<$Res>  {
  factory $WorkCopyWith(Work value, $Res Function(Work) _then) = _$WorkCopyWithImpl;
@useResult
$Res call({
@HiveField(0) int id,@HiveField(1) String? title,@HiveField(2)@JsonKey(name: 'circle_id') int? circleId,@HiveField(3) String? name,@HiveField(4) bool? nsfw,@HiveField(5) String? release,@HiveField(6)@JsonKey(name: 'dl_count') int? dlCount,@HiveField(7) int? price,@HiveField(8)@JsonKey(name: 'review_count') int? reviewCount,@HiveField(9)@JsonKey(name: 'review_text') String? reviewText,@HiveField(10)@JsonKey(name: 'rate_count') int? rateCount,@HiveField(11)@JsonKey(name: 'rate_average_2dp') double? rateAverage2dp,@HiveField(12)@JsonKey(name: 'rate_count_detail') List<RateCountDetail>? rateCountDetail,@HiveField(13) List<Rank>? rank,@HiveField(14)@JsonKey(name: 'has_subtitle') bool? hasSubtitle,@HiveField(15)@JsonKey(name: 'create_date') String? createDate,@HiveField(16) List<VA>? vas,@HiveField(17) List<Tag>? tags,@HiveField(18)@JsonKey(name: 'original_workno') String? originalWorkno,@HiveField(19)@JsonKey(name: 'other_language_editions_in_db') List<OtherLanguageEdition>? otherLanguageEditionsInDb,@HiveField(20)@JsonKey(name: 'work_attributes') String? workAttributes,@HiveField(21)@JsonKey(name: 'age_category_string') String? ageCategoryString,@HiveField(22) int? duration,@HiveField(23)@JsonKey(name: 'source_type') String? sourceType,@HiveField(24)@JsonKey(name: 'source_id') String? sourceId,@HiveField(25)@JsonKey(name: 'source_url') String? sourceUrl,@HiveField(26)@JsonKey(name: 'updated_at') String? updatedAt,@HiveField(27) dynamic userRating,@HiveField(28) Map<String, bool>? playlistStatus,@HiveField(29) Circle? circle,@HiveField(30) String? samCoverUrl,@HiveField(31) String? thumbnailCoverUrl,@HiveField(32) String? mainCoverUrl,@HiveField(33) String? progress,@JsonKey(includeFromJson: false, includeToJson: false) String? heroTag
});


$CircleCopyWith<$Res>? get circle;

}
/// @nodoc
class _$WorkCopyWithImpl<$Res>
    implements $WorkCopyWith<$Res> {
  _$WorkCopyWithImpl(this._self, this._then);

  final Work _self;
  final $Res Function(Work) _then;

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? circleId = freezed,Object? name = freezed,Object? nsfw = freezed,Object? release = freezed,Object? dlCount = freezed,Object? price = freezed,Object? reviewCount = freezed,Object? reviewText = freezed,Object? rateCount = freezed,Object? rateAverage2dp = freezed,Object? rateCountDetail = freezed,Object? rank = freezed,Object? hasSubtitle = freezed,Object? createDate = freezed,Object? vas = freezed,Object? tags = freezed,Object? originalWorkno = freezed,Object? otherLanguageEditionsInDb = freezed,Object? workAttributes = freezed,Object? ageCategoryString = freezed,Object? duration = freezed,Object? sourceType = freezed,Object? sourceId = freezed,Object? sourceUrl = freezed,Object? updatedAt = freezed,Object? userRating = freezed,Object? playlistStatus = freezed,Object? circle = freezed,Object? samCoverUrl = freezed,Object? thumbnailCoverUrl = freezed,Object? mainCoverUrl = freezed,Object? progress = freezed,Object? heroTag = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,circleId: freezed == circleId ? _self.circleId : circleId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nsfw: freezed == nsfw ? _self.nsfw : nsfw // ignore: cast_nullable_to_non_nullable
as bool?,release: freezed == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as String?,dlCount: freezed == dlCount ? _self.dlCount : dlCount // ignore: cast_nullable_to_non_nullable
as int?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int?,reviewCount: freezed == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int?,reviewText: freezed == reviewText ? _self.reviewText : reviewText // ignore: cast_nullable_to_non_nullable
as String?,rateCount: freezed == rateCount ? _self.rateCount : rateCount // ignore: cast_nullable_to_non_nullable
as int?,rateAverage2dp: freezed == rateAverage2dp ? _self.rateAverage2dp : rateAverage2dp // ignore: cast_nullable_to_non_nullable
as double?,rateCountDetail: freezed == rateCountDetail ? _self.rateCountDetail : rateCountDetail // ignore: cast_nullable_to_non_nullable
as List<RateCountDetail>?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as List<Rank>?,hasSubtitle: freezed == hasSubtitle ? _self.hasSubtitle : hasSubtitle // ignore: cast_nullable_to_non_nullable
as bool?,createDate: freezed == createDate ? _self.createDate : createDate // ignore: cast_nullable_to_non_nullable
as String?,vas: freezed == vas ? _self.vas : vas // ignore: cast_nullable_to_non_nullable
as List<VA>?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<Tag>?,originalWorkno: freezed == originalWorkno ? _self.originalWorkno : originalWorkno // ignore: cast_nullable_to_non_nullable
as String?,otherLanguageEditionsInDb: freezed == otherLanguageEditionsInDb ? _self.otherLanguageEditionsInDb : otherLanguageEditionsInDb // ignore: cast_nullable_to_non_nullable
as List<OtherLanguageEdition>?,workAttributes: freezed == workAttributes ? _self.workAttributes : workAttributes // ignore: cast_nullable_to_non_nullable
as String?,ageCategoryString: freezed == ageCategoryString ? _self.ageCategoryString : ageCategoryString // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as dynamic,playlistStatus: freezed == playlistStatus ? _self.playlistStatus : playlistStatus // ignore: cast_nullable_to_non_nullable
as Map<String, bool>?,circle: freezed == circle ? _self.circle : circle // ignore: cast_nullable_to_non_nullable
as Circle?,samCoverUrl: freezed == samCoverUrl ? _self.samCoverUrl : samCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailCoverUrl: freezed == thumbnailCoverUrl ? _self.thumbnailCoverUrl : thumbnailCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,mainCoverUrl: freezed == mainCoverUrl ? _self.mainCoverUrl : mainCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as String?,heroTag: freezed == heroTag ? _self.heroTag : heroTag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CircleCopyWith<$Res>? get circle {
    if (_self.circle == null) {
    return null;
  }

  return $CircleCopyWith<$Res>(_self.circle!, (value) {
    return _then(_self.copyWith(circle: value));
  });
}
}


/// Adds pattern-matching-related methods to [Work].
extension WorkPatterns on Work {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Work value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Work() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Work value)  $default,){
final _that = this;
switch (_that) {
case _Work():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Work value)?  $default,){
final _that = this;
switch (_that) {
case _Work() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  int id, @HiveField(1)  String? title, @HiveField(2)@JsonKey(name: 'circle_id')  int? circleId, @HiveField(3)  String? name, @HiveField(4)  bool? nsfw, @HiveField(5)  String? release, @HiveField(6)@JsonKey(name: 'dl_count')  int? dlCount, @HiveField(7)  int? price, @HiveField(8)@JsonKey(name: 'review_count')  int? reviewCount, @HiveField(9)@JsonKey(name: 'review_text')  String? reviewText, @HiveField(10)@JsonKey(name: 'rate_count')  int? rateCount, @HiveField(11)@JsonKey(name: 'rate_average_2dp')  double? rateAverage2dp, @HiveField(12)@JsonKey(name: 'rate_count_detail')  List<RateCountDetail>? rateCountDetail, @HiveField(13)  List<Rank>? rank, @HiveField(14)@JsonKey(name: 'has_subtitle')  bool? hasSubtitle, @HiveField(15)@JsonKey(name: 'create_date')  String? createDate, @HiveField(16)  List<VA>? vas, @HiveField(17)  List<Tag>? tags, @HiveField(18)@JsonKey(name: 'original_workno')  String? originalWorkno, @HiveField(19)@JsonKey(name: 'other_language_editions_in_db')  List<OtherLanguageEdition>? otherLanguageEditionsInDb, @HiveField(20)@JsonKey(name: 'work_attributes')  String? workAttributes, @HiveField(21)@JsonKey(name: 'age_category_string')  String? ageCategoryString, @HiveField(22)  int? duration, @HiveField(23)@JsonKey(name: 'source_type')  String? sourceType, @HiveField(24)@JsonKey(name: 'source_id')  String? sourceId, @HiveField(25)@JsonKey(name: 'source_url')  String? sourceUrl, @HiveField(26)@JsonKey(name: 'updated_at')  String? updatedAt, @HiveField(27)  dynamic userRating, @HiveField(28)  Map<String, bool>? playlistStatus, @HiveField(29)  Circle? circle, @HiveField(30)  String? samCoverUrl, @HiveField(31)  String? thumbnailCoverUrl, @HiveField(32)  String? mainCoverUrl, @HiveField(33)  String? progress, @JsonKey(includeFromJson: false, includeToJson: false)  String? heroTag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Work() when $default != null:
return $default(_that.id,_that.title,_that.circleId,_that.name,_that.nsfw,_that.release,_that.dlCount,_that.price,_that.reviewCount,_that.reviewText,_that.rateCount,_that.rateAverage2dp,_that.rateCountDetail,_that.rank,_that.hasSubtitle,_that.createDate,_that.vas,_that.tags,_that.originalWorkno,_that.otherLanguageEditionsInDb,_that.workAttributes,_that.ageCategoryString,_that.duration,_that.sourceType,_that.sourceId,_that.sourceUrl,_that.updatedAt,_that.userRating,_that.playlistStatus,_that.circle,_that.samCoverUrl,_that.thumbnailCoverUrl,_that.mainCoverUrl,_that.progress,_that.heroTag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  int id, @HiveField(1)  String? title, @HiveField(2)@JsonKey(name: 'circle_id')  int? circleId, @HiveField(3)  String? name, @HiveField(4)  bool? nsfw, @HiveField(5)  String? release, @HiveField(6)@JsonKey(name: 'dl_count')  int? dlCount, @HiveField(7)  int? price, @HiveField(8)@JsonKey(name: 'review_count')  int? reviewCount, @HiveField(9)@JsonKey(name: 'review_text')  String? reviewText, @HiveField(10)@JsonKey(name: 'rate_count')  int? rateCount, @HiveField(11)@JsonKey(name: 'rate_average_2dp')  double? rateAverage2dp, @HiveField(12)@JsonKey(name: 'rate_count_detail')  List<RateCountDetail>? rateCountDetail, @HiveField(13)  List<Rank>? rank, @HiveField(14)@JsonKey(name: 'has_subtitle')  bool? hasSubtitle, @HiveField(15)@JsonKey(name: 'create_date')  String? createDate, @HiveField(16)  List<VA>? vas, @HiveField(17)  List<Tag>? tags, @HiveField(18)@JsonKey(name: 'original_workno')  String? originalWorkno, @HiveField(19)@JsonKey(name: 'other_language_editions_in_db')  List<OtherLanguageEdition>? otherLanguageEditionsInDb, @HiveField(20)@JsonKey(name: 'work_attributes')  String? workAttributes, @HiveField(21)@JsonKey(name: 'age_category_string')  String? ageCategoryString, @HiveField(22)  int? duration, @HiveField(23)@JsonKey(name: 'source_type')  String? sourceType, @HiveField(24)@JsonKey(name: 'source_id')  String? sourceId, @HiveField(25)@JsonKey(name: 'source_url')  String? sourceUrl, @HiveField(26)@JsonKey(name: 'updated_at')  String? updatedAt, @HiveField(27)  dynamic userRating, @HiveField(28)  Map<String, bool>? playlistStatus, @HiveField(29)  Circle? circle, @HiveField(30)  String? samCoverUrl, @HiveField(31)  String? thumbnailCoverUrl, @HiveField(32)  String? mainCoverUrl, @HiveField(33)  String? progress, @JsonKey(includeFromJson: false, includeToJson: false)  String? heroTag)  $default,) {final _that = this;
switch (_that) {
case _Work():
return $default(_that.id,_that.title,_that.circleId,_that.name,_that.nsfw,_that.release,_that.dlCount,_that.price,_that.reviewCount,_that.reviewText,_that.rateCount,_that.rateAverage2dp,_that.rateCountDetail,_that.rank,_that.hasSubtitle,_that.createDate,_that.vas,_that.tags,_that.originalWorkno,_that.otherLanguageEditionsInDb,_that.workAttributes,_that.ageCategoryString,_that.duration,_that.sourceType,_that.sourceId,_that.sourceUrl,_that.updatedAt,_that.userRating,_that.playlistStatus,_that.circle,_that.samCoverUrl,_that.thumbnailCoverUrl,_that.mainCoverUrl,_that.progress,_that.heroTag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  int id, @HiveField(1)  String? title, @HiveField(2)@JsonKey(name: 'circle_id')  int? circleId, @HiveField(3)  String? name, @HiveField(4)  bool? nsfw, @HiveField(5)  String? release, @HiveField(6)@JsonKey(name: 'dl_count')  int? dlCount, @HiveField(7)  int? price, @HiveField(8)@JsonKey(name: 'review_count')  int? reviewCount, @HiveField(9)@JsonKey(name: 'review_text')  String? reviewText, @HiveField(10)@JsonKey(name: 'rate_count')  int? rateCount, @HiveField(11)@JsonKey(name: 'rate_average_2dp')  double? rateAverage2dp, @HiveField(12)@JsonKey(name: 'rate_count_detail')  List<RateCountDetail>? rateCountDetail, @HiveField(13)  List<Rank>? rank, @HiveField(14)@JsonKey(name: 'has_subtitle')  bool? hasSubtitle, @HiveField(15)@JsonKey(name: 'create_date')  String? createDate, @HiveField(16)  List<VA>? vas, @HiveField(17)  List<Tag>? tags, @HiveField(18)@JsonKey(name: 'original_workno')  String? originalWorkno, @HiveField(19)@JsonKey(name: 'other_language_editions_in_db')  List<OtherLanguageEdition>? otherLanguageEditionsInDb, @HiveField(20)@JsonKey(name: 'work_attributes')  String? workAttributes, @HiveField(21)@JsonKey(name: 'age_category_string')  String? ageCategoryString, @HiveField(22)  int? duration, @HiveField(23)@JsonKey(name: 'source_type')  String? sourceType, @HiveField(24)@JsonKey(name: 'source_id')  String? sourceId, @HiveField(25)@JsonKey(name: 'source_url')  String? sourceUrl, @HiveField(26)@JsonKey(name: 'updated_at')  String? updatedAt, @HiveField(27)  dynamic userRating, @HiveField(28)  Map<String, bool>? playlistStatus, @HiveField(29)  Circle? circle, @HiveField(30)  String? samCoverUrl, @HiveField(31)  String? thumbnailCoverUrl, @HiveField(32)  String? mainCoverUrl, @HiveField(33)  String? progress, @JsonKey(includeFromJson: false, includeToJson: false)  String? heroTag)?  $default,) {final _that = this;
switch (_that) {
case _Work() when $default != null:
return $default(_that.id,_that.title,_that.circleId,_that.name,_that.nsfw,_that.release,_that.dlCount,_that.price,_that.reviewCount,_that.reviewText,_that.rateCount,_that.rateAverage2dp,_that.rateCountDetail,_that.rank,_that.hasSubtitle,_that.createDate,_that.vas,_that.tags,_that.originalWorkno,_that.otherLanguageEditionsInDb,_that.workAttributes,_that.ageCategoryString,_that.duration,_that.sourceType,_that.sourceId,_that.sourceUrl,_that.updatedAt,_that.userRating,_that.playlistStatus,_that.circle,_that.samCoverUrl,_that.thumbnailCoverUrl,_that.mainCoverUrl,_that.progress,_that.heroTag);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Work extends Work {
  const _Work({@HiveField(0) required this.id, @HiveField(1) this.title, @HiveField(2)@JsonKey(name: 'circle_id') this.circleId, @HiveField(3) this.name, @HiveField(4) this.nsfw, @HiveField(5) this.release, @HiveField(6)@JsonKey(name: 'dl_count') this.dlCount, @HiveField(7) this.price, @HiveField(8)@JsonKey(name: 'review_count') this.reviewCount, @HiveField(9)@JsonKey(name: 'review_text') this.reviewText, @HiveField(10)@JsonKey(name: 'rate_count') this.rateCount, @HiveField(11)@JsonKey(name: 'rate_average_2dp') this.rateAverage2dp, @HiveField(12)@JsonKey(name: 'rate_count_detail') final  List<RateCountDetail>? rateCountDetail, @HiveField(13) final  List<Rank>? rank, @HiveField(14)@JsonKey(name: 'has_subtitle') this.hasSubtitle, @HiveField(15)@JsonKey(name: 'create_date') this.createDate, @HiveField(16) final  List<VA>? vas, @HiveField(17) final  List<Tag>? tags, @HiveField(18)@JsonKey(name: 'original_workno') this.originalWorkno, @HiveField(19)@JsonKey(name: 'other_language_editions_in_db') final  List<OtherLanguageEdition>? otherLanguageEditionsInDb, @HiveField(20)@JsonKey(name: 'work_attributes') this.workAttributes, @HiveField(21)@JsonKey(name: 'age_category_string') this.ageCategoryString, @HiveField(22) this.duration, @HiveField(23)@JsonKey(name: 'source_type') this.sourceType, @HiveField(24)@JsonKey(name: 'source_id') this.sourceId, @HiveField(25)@JsonKey(name: 'source_url') this.sourceUrl, @HiveField(26)@JsonKey(name: 'updated_at') this.updatedAt, @HiveField(27) this.userRating, @HiveField(28) final  Map<String, bool>? playlistStatus, @HiveField(29) this.circle, @HiveField(30) this.samCoverUrl, @HiveField(31) this.thumbnailCoverUrl, @HiveField(32) this.mainCoverUrl, @HiveField(33) this.progress, @JsonKey(includeFromJson: false, includeToJson: false) this.heroTag}): _rateCountDetail = rateCountDetail,_rank = rank,_vas = vas,_tags = tags,_otherLanguageEditionsInDb = otherLanguageEditionsInDb,_playlistStatus = playlistStatus,super._();
  factory _Work.fromJson(Map<String, dynamic> json) => _$WorkFromJson(json);

@override@HiveField(0) final  int id;
@override@HiveField(1) final  String? title;
@override@HiveField(2)@JsonKey(name: 'circle_id') final  int? circleId;
@override@HiveField(3) final  String? name;
@override@HiveField(4) final  bool? nsfw;
@override@HiveField(5) final  String? release;
@override@HiveField(6)@JsonKey(name: 'dl_count') final  int? dlCount;
@override@HiveField(7) final  int? price;
@override@HiveField(8)@JsonKey(name: 'review_count') final  int? reviewCount;
@override@HiveField(9)@JsonKey(name: 'review_text') final  String? reviewText;
@override@HiveField(10)@JsonKey(name: 'rate_count') final  int? rateCount;
@override@HiveField(11)@JsonKey(name: 'rate_average_2dp') final  double? rateAverage2dp;
 final  List<RateCountDetail>? _rateCountDetail;
@override@HiveField(12)@JsonKey(name: 'rate_count_detail') List<RateCountDetail>? get rateCountDetail {
  final value = _rateCountDetail;
  if (value == null) return null;
  if (_rateCountDetail is EqualUnmodifiableListView) return _rateCountDetail;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Rank>? _rank;
@override@HiveField(13) List<Rank>? get rank {
  final value = _rank;
  if (value == null) return null;
  if (_rank is EqualUnmodifiableListView) return _rank;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@HiveField(14)@JsonKey(name: 'has_subtitle') final  bool? hasSubtitle;
@override@HiveField(15)@JsonKey(name: 'create_date') final  String? createDate;
 final  List<VA>? _vas;
@override@HiveField(16) List<VA>? get vas {
  final value = _vas;
  if (value == null) return null;
  if (_vas is EqualUnmodifiableListView) return _vas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Tag>? _tags;
@override@HiveField(17) List<Tag>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@HiveField(18)@JsonKey(name: 'original_workno') final  String? originalWorkno;
 final  List<OtherLanguageEdition>? _otherLanguageEditionsInDb;
@override@HiveField(19)@JsonKey(name: 'other_language_editions_in_db') List<OtherLanguageEdition>? get otherLanguageEditionsInDb {
  final value = _otherLanguageEditionsInDb;
  if (value == null) return null;
  if (_otherLanguageEditionsInDb is EqualUnmodifiableListView) return _otherLanguageEditionsInDb;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@HiveField(20)@JsonKey(name: 'work_attributes') final  String? workAttributes;
@override@HiveField(21)@JsonKey(name: 'age_category_string') final  String? ageCategoryString;
@override@HiveField(22) final  int? duration;
@override@HiveField(23)@JsonKey(name: 'source_type') final  String? sourceType;
@override@HiveField(24)@JsonKey(name: 'source_id') final  String? sourceId;
@override@HiveField(25)@JsonKey(name: 'source_url') final  String? sourceUrl;
@override@HiveField(26)@JsonKey(name: 'updated_at') final  String? updatedAt;
@override@HiveField(27) final  dynamic userRating;
 final  Map<String, bool>? _playlistStatus;
@override@HiveField(28) Map<String, bool>? get playlistStatus {
  final value = _playlistStatus;
  if (value == null) return null;
  if (_playlistStatus is EqualUnmodifiableMapView) return _playlistStatus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@HiveField(29) final  Circle? circle;
@override@HiveField(30) final  String? samCoverUrl;
@override@HiveField(31) final  String? thumbnailCoverUrl;
@override@HiveField(32) final  String? mainCoverUrl;
@override@HiveField(33) final  String? progress;
/// Hero animation unique identifier (excluded from JSON and Hive persistence)
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? heroTag;

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkCopyWith<_Work> get copyWith => __$WorkCopyWithImpl<_Work>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Work&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.circleId, circleId) || other.circleId == circleId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nsfw, nsfw) || other.nsfw == nsfw)&&(identical(other.release, release) || other.release == release)&&(identical(other.dlCount, dlCount) || other.dlCount == dlCount)&&(identical(other.price, price) || other.price == price)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.reviewText, reviewText) || other.reviewText == reviewText)&&(identical(other.rateCount, rateCount) || other.rateCount == rateCount)&&(identical(other.rateAverage2dp, rateAverage2dp) || other.rateAverage2dp == rateAverage2dp)&&const DeepCollectionEquality().equals(other._rateCountDetail, _rateCountDetail)&&const DeepCollectionEquality().equals(other._rank, _rank)&&(identical(other.hasSubtitle, hasSubtitle) || other.hasSubtitle == hasSubtitle)&&(identical(other.createDate, createDate) || other.createDate == createDate)&&const DeepCollectionEquality().equals(other._vas, _vas)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.originalWorkno, originalWorkno) || other.originalWorkno == originalWorkno)&&const DeepCollectionEquality().equals(other._otherLanguageEditionsInDb, _otherLanguageEditionsInDb)&&(identical(other.workAttributes, workAttributes) || other.workAttributes == workAttributes)&&(identical(other.ageCategoryString, ageCategoryString) || other.ageCategoryString == ageCategoryString)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.userRating, userRating)&&const DeepCollectionEquality().equals(other._playlistStatus, _playlistStatus)&&(identical(other.circle, circle) || other.circle == circle)&&(identical(other.samCoverUrl, samCoverUrl) || other.samCoverUrl == samCoverUrl)&&(identical(other.thumbnailCoverUrl, thumbnailCoverUrl) || other.thumbnailCoverUrl == thumbnailCoverUrl)&&(identical(other.mainCoverUrl, mainCoverUrl) || other.mainCoverUrl == mainCoverUrl)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.heroTag, heroTag) || other.heroTag == heroTag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,circleId,name,nsfw,release,dlCount,price,reviewCount,reviewText,rateCount,rateAverage2dp,const DeepCollectionEquality().hash(_rateCountDetail),const DeepCollectionEquality().hash(_rank),hasSubtitle,createDate,const DeepCollectionEquality().hash(_vas),const DeepCollectionEquality().hash(_tags),originalWorkno,const DeepCollectionEquality().hash(_otherLanguageEditionsInDb),workAttributes,ageCategoryString,duration,sourceType,sourceId,sourceUrl,updatedAt,const DeepCollectionEquality().hash(userRating),const DeepCollectionEquality().hash(_playlistStatus),circle,samCoverUrl,thumbnailCoverUrl,mainCoverUrl,progress,heroTag]);

@override
String toString() {
  return 'Work(id: $id, title: $title, circleId: $circleId, name: $name, nsfw: $nsfw, release: $release, dlCount: $dlCount, price: $price, reviewCount: $reviewCount, reviewText: $reviewText, rateCount: $rateCount, rateAverage2dp: $rateAverage2dp, rateCountDetail: $rateCountDetail, rank: $rank, hasSubtitle: $hasSubtitle, createDate: $createDate, vas: $vas, tags: $tags, originalWorkno: $originalWorkno, otherLanguageEditionsInDb: $otherLanguageEditionsInDb, workAttributes: $workAttributes, ageCategoryString: $ageCategoryString, duration: $duration, sourceType: $sourceType, sourceId: $sourceId, sourceUrl: $sourceUrl, updatedAt: $updatedAt, userRating: $userRating, playlistStatus: $playlistStatus, circle: $circle, samCoverUrl: $samCoverUrl, thumbnailCoverUrl: $thumbnailCoverUrl, mainCoverUrl: $mainCoverUrl, progress: $progress, heroTag: $heroTag)';
}


}

/// @nodoc
abstract mixin class _$WorkCopyWith<$Res> implements $WorkCopyWith<$Res> {
  factory _$WorkCopyWith(_Work value, $Res Function(_Work) _then) = __$WorkCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) int id,@HiveField(1) String? title,@HiveField(2)@JsonKey(name: 'circle_id') int? circleId,@HiveField(3) String? name,@HiveField(4) bool? nsfw,@HiveField(5) String? release,@HiveField(6)@JsonKey(name: 'dl_count') int? dlCount,@HiveField(7) int? price,@HiveField(8)@JsonKey(name: 'review_count') int? reviewCount,@HiveField(9)@JsonKey(name: 'review_text') String? reviewText,@HiveField(10)@JsonKey(name: 'rate_count') int? rateCount,@HiveField(11)@JsonKey(name: 'rate_average_2dp') double? rateAverage2dp,@HiveField(12)@JsonKey(name: 'rate_count_detail') List<RateCountDetail>? rateCountDetail,@HiveField(13) List<Rank>? rank,@HiveField(14)@JsonKey(name: 'has_subtitle') bool? hasSubtitle,@HiveField(15)@JsonKey(name: 'create_date') String? createDate,@HiveField(16) List<VA>? vas,@HiveField(17) List<Tag>? tags,@HiveField(18)@JsonKey(name: 'original_workno') String? originalWorkno,@HiveField(19)@JsonKey(name: 'other_language_editions_in_db') List<OtherLanguageEdition>? otherLanguageEditionsInDb,@HiveField(20)@JsonKey(name: 'work_attributes') String? workAttributes,@HiveField(21)@JsonKey(name: 'age_category_string') String? ageCategoryString,@HiveField(22) int? duration,@HiveField(23)@JsonKey(name: 'source_type') String? sourceType,@HiveField(24)@JsonKey(name: 'source_id') String? sourceId,@HiveField(25)@JsonKey(name: 'source_url') String? sourceUrl,@HiveField(26)@JsonKey(name: 'updated_at') String? updatedAt,@HiveField(27) dynamic userRating,@HiveField(28) Map<String, bool>? playlistStatus,@HiveField(29) Circle? circle,@HiveField(30) String? samCoverUrl,@HiveField(31) String? thumbnailCoverUrl,@HiveField(32) String? mainCoverUrl,@HiveField(33) String? progress,@JsonKey(includeFromJson: false, includeToJson: false) String? heroTag
});


@override $CircleCopyWith<$Res>? get circle;

}
/// @nodoc
class __$WorkCopyWithImpl<$Res>
    implements _$WorkCopyWith<$Res> {
  __$WorkCopyWithImpl(this._self, this._then);

  final _Work _self;
  final $Res Function(_Work) _then;

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? circleId = freezed,Object? name = freezed,Object? nsfw = freezed,Object? release = freezed,Object? dlCount = freezed,Object? price = freezed,Object? reviewCount = freezed,Object? reviewText = freezed,Object? rateCount = freezed,Object? rateAverage2dp = freezed,Object? rateCountDetail = freezed,Object? rank = freezed,Object? hasSubtitle = freezed,Object? createDate = freezed,Object? vas = freezed,Object? tags = freezed,Object? originalWorkno = freezed,Object? otherLanguageEditionsInDb = freezed,Object? workAttributes = freezed,Object? ageCategoryString = freezed,Object? duration = freezed,Object? sourceType = freezed,Object? sourceId = freezed,Object? sourceUrl = freezed,Object? updatedAt = freezed,Object? userRating = freezed,Object? playlistStatus = freezed,Object? circle = freezed,Object? samCoverUrl = freezed,Object? thumbnailCoverUrl = freezed,Object? mainCoverUrl = freezed,Object? progress = freezed,Object? heroTag = freezed,}) {
  return _then(_Work(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,circleId: freezed == circleId ? _self.circleId : circleId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nsfw: freezed == nsfw ? _self.nsfw : nsfw // ignore: cast_nullable_to_non_nullable
as bool?,release: freezed == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as String?,dlCount: freezed == dlCount ? _self.dlCount : dlCount // ignore: cast_nullable_to_non_nullable
as int?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int?,reviewCount: freezed == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int?,reviewText: freezed == reviewText ? _self.reviewText : reviewText // ignore: cast_nullable_to_non_nullable
as String?,rateCount: freezed == rateCount ? _self.rateCount : rateCount // ignore: cast_nullable_to_non_nullable
as int?,rateAverage2dp: freezed == rateAverage2dp ? _self.rateAverage2dp : rateAverage2dp // ignore: cast_nullable_to_non_nullable
as double?,rateCountDetail: freezed == rateCountDetail ? _self._rateCountDetail : rateCountDetail // ignore: cast_nullable_to_non_nullable
as List<RateCountDetail>?,rank: freezed == rank ? _self._rank : rank // ignore: cast_nullable_to_non_nullable
as List<Rank>?,hasSubtitle: freezed == hasSubtitle ? _self.hasSubtitle : hasSubtitle // ignore: cast_nullable_to_non_nullable
as bool?,createDate: freezed == createDate ? _self.createDate : createDate // ignore: cast_nullable_to_non_nullable
as String?,vas: freezed == vas ? _self._vas : vas // ignore: cast_nullable_to_non_nullable
as List<VA>?,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<Tag>?,originalWorkno: freezed == originalWorkno ? _self.originalWorkno : originalWorkno // ignore: cast_nullable_to_non_nullable
as String?,otherLanguageEditionsInDb: freezed == otherLanguageEditionsInDb ? _self._otherLanguageEditionsInDb : otherLanguageEditionsInDb // ignore: cast_nullable_to_non_nullable
as List<OtherLanguageEdition>?,workAttributes: freezed == workAttributes ? _self.workAttributes : workAttributes // ignore: cast_nullable_to_non_nullable
as String?,ageCategoryString: freezed == ageCategoryString ? _self.ageCategoryString : ageCategoryString // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as dynamic,playlistStatus: freezed == playlistStatus ? _self._playlistStatus : playlistStatus // ignore: cast_nullable_to_non_nullable
as Map<String, bool>?,circle: freezed == circle ? _self.circle : circle // ignore: cast_nullable_to_non_nullable
as Circle?,samCoverUrl: freezed == samCoverUrl ? _self.samCoverUrl : samCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailCoverUrl: freezed == thumbnailCoverUrl ? _self.thumbnailCoverUrl : thumbnailCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,mainCoverUrl: freezed == mainCoverUrl ? _self.mainCoverUrl : mainCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as String?,heroTag: freezed == heroTag ? _self.heroTag : heroTag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CircleCopyWith<$Res>? get circle {
    if (_self.circle == null) {
    return null;
  }

  return $CircleCopyWith<$Res>(_self.circle!, (value) {
    return _then(_self.copyWith(circle: value));
  });
}
}

// dart format on
