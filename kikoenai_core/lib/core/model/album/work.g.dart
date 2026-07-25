// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkAdapter extends TypeAdapter<Work> {
  @override
  final typeId = 11;

  @override
  Work read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Work(
      id: (fields[0] as num).toInt(),
      title: fields[1] as String?,
      circleId: (fields[2] as num?)?.toInt(),
      name: fields[3] as String?,
      nsfw: fields[4] as bool?,
      release: fields[5] as String?,
      dlCount: (fields[6] as num?)?.toInt(),
      price: (fields[7] as num?)?.toInt(),
      reviewCount: (fields[8] as num?)?.toInt(),
      reviewText: fields[9] as String?,
      rateCount: (fields[10] as num?)?.toInt(),
      rateAverage2dp: (fields[11] as num?)?.toDouble(),
      rateCountDetail: (fields[12] as List?)?.cast<RateCountDetail>(),
      rank: (fields[13] as List?)?.cast<Rank>(),
      hasSubtitle: fields[14] as bool?,
      createDate: fields[15] as String?,
      vas: (fields[16] as List?)?.cast<VA>(),
      tags: (fields[17] as List?)?.cast<Tag>(),
      originalWorkno: fields[18] as String?,
      otherLanguageEditionsInDb: (fields[19] as List?)
          ?.cast<OtherLanguageEdition>(),
      workAttributes: fields[20] as String?,
      ageCategoryString: fields[21] as String?,
      duration: (fields[22] as num?)?.toInt(),
      sourceType: fields[23] as String?,
      sourceId: fields[24] as String?,
      sourceUrl: fields[25] as String?,
      updatedAt: fields[26] as String?,
      userRating: fields[27] as dynamic,
      playlistStatus: (fields[28] as Map?)?.cast<String, bool>(),
      circle: fields[29] as Circle?,
      samCoverUrl: fields[30] as String?,
      thumbnailCoverUrl: fields[31] as String?,
      mainCoverUrl: fields[32] as String?,
      progress: fields[33] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Work obj) {
    writer
      ..writeByte(34)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.circleId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.nsfw)
      ..writeByte(5)
      ..write(obj.release)
      ..writeByte(6)
      ..write(obj.dlCount)
      ..writeByte(7)
      ..write(obj.price)
      ..writeByte(8)
      ..write(obj.reviewCount)
      ..writeByte(9)
      ..write(obj.reviewText)
      ..writeByte(10)
      ..write(obj.rateCount)
      ..writeByte(11)
      ..write(obj.rateAverage2dp)
      ..writeByte(12)
      ..write(obj.rateCountDetail)
      ..writeByte(13)
      ..write(obj.rank)
      ..writeByte(14)
      ..write(obj.hasSubtitle)
      ..writeByte(15)
      ..write(obj.createDate)
      ..writeByte(16)
      ..write(obj.vas)
      ..writeByte(17)
      ..write(obj.tags)
      ..writeByte(18)
      ..write(obj.originalWorkno)
      ..writeByte(19)
      ..write(obj.otherLanguageEditionsInDb)
      ..writeByte(20)
      ..write(obj.workAttributes)
      ..writeByte(21)
      ..write(obj.ageCategoryString)
      ..writeByte(22)
      ..write(obj.duration)
      ..writeByte(23)
      ..write(obj.sourceType)
      ..writeByte(24)
      ..write(obj.sourceId)
      ..writeByte(25)
      ..write(obj.sourceUrl)
      ..writeByte(26)
      ..write(obj.updatedAt)
      ..writeByte(27)
      ..write(obj.userRating)
      ..writeByte(28)
      ..write(obj.playlistStatus)
      ..writeByte(29)
      ..write(obj.circle)
      ..writeByte(30)
      ..write(obj.samCoverUrl)
      ..writeByte(31)
      ..write(obj.thumbnailCoverUrl)
      ..writeByte(32)
      ..write(obj.mainCoverUrl)
      ..writeByte(33)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Work _$WorkFromJson(Map<String, dynamic> json) => _Work(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String?,
  circleId: (json['circle_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  nsfw: json['nsfw'] as bool?,
  release: json['release'] as String?,
  dlCount: (json['dl_count'] as num?)?.toInt(),
  price: (json['price'] as num?)?.toInt(),
  reviewCount: (json['review_count'] as num?)?.toInt(),
  reviewText: json['review_text'] as String?,
  rateCount: (json['rate_count'] as num?)?.toInt(),
  rateAverage2dp: (json['rate_average_2dp'] as num?)?.toDouble(),
  rateCountDetail: (json['rate_count_detail'] as List<dynamic>?)
      ?.map((e) => RateCountDetail.fromJson(e as Map<String, dynamic>))
      .toList(),
  rank: (json['rank'] as List<dynamic>?)
      ?.map((e) => Rank.fromJson(e as Map<String, dynamic>))
      .toList(),
  hasSubtitle: json['has_subtitle'] as bool?,
  createDate: json['create_date'] as String?,
  vas: (json['vas'] as List<dynamic>?)
      ?.map((e) => VA.fromJson(e as Map<String, dynamic>))
      .toList(),
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
      .toList(),
  originalWorkno: json['original_workno'] as String?,
  otherLanguageEditionsInDb:
      (json['other_language_editions_in_db'] as List<dynamic>?)
          ?.map((e) => OtherLanguageEdition.fromJson(e as Map<String, dynamic>))
          .toList(),
  workAttributes: json['work_attributes'] as String?,
  ageCategoryString: json['age_category_string'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  sourceType: json['source_type'] as String?,
  sourceId: json['source_id'] as String?,
  sourceUrl: json['source_url'] as String?,
  updatedAt: json['updated_at'] as String?,
  userRating: json['userRating'],
  playlistStatus: (json['playlistStatus'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
  circle: json['circle'] == null
      ? null
      : Circle.fromJson(json['circle'] as Map<String, dynamic>),
  samCoverUrl: json['samCoverUrl'] as String?,
  thumbnailCoverUrl: json['thumbnailCoverUrl'] as String?,
  mainCoverUrl: json['mainCoverUrl'] as String?,
  progress: json['progress'] as String?,
);

Map<String, dynamic> _$WorkToJson(_Work instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'circle_id': instance.circleId,
  'name': instance.name,
  'nsfw': instance.nsfw,
  'release': instance.release,
  'dl_count': instance.dlCount,
  'price': instance.price,
  'review_count': instance.reviewCount,
  'review_text': instance.reviewText,
  'rate_count': instance.rateCount,
  'rate_average_2dp': instance.rateAverage2dp,
  'rate_count_detail': instance.rateCountDetail,
  'rank': instance.rank,
  'has_subtitle': instance.hasSubtitle,
  'create_date': instance.createDate,
  'vas': instance.vas,
  'tags': instance.tags,
  'original_workno': instance.originalWorkno,
  'other_language_editions_in_db': instance.otherLanguageEditionsInDb,
  'work_attributes': instance.workAttributes,
  'age_category_string': instance.ageCategoryString,
  'duration': instance.duration,
  'source_type': instance.sourceType,
  'source_id': instance.sourceId,
  'source_url': instance.sourceUrl,
  'updated_at': instance.updatedAt,
  'userRating': instance.userRating,
  'playlistStatus': instance.playlistStatus,
  'circle': instance.circle,
  'samCoverUrl': instance.samCoverUrl,
  'thumbnailCoverUrl': instance.thumbnailCoverUrl,
  'mainCoverUrl': instance.mainCoverUrl,
  'progress': instance.progress,
};
