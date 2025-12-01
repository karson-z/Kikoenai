// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'other_language_edition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtherLanguageEdition _$OtherLanguageEditionFromJson(
        Map<String, dynamic> json) =>
    OtherLanguageEdition(
      id: (json['id'] as num?)?.toInt(),
      lang: json['lang'] as String?,
      title: json['title'] as String?,
      sourceId: json['source_id'] as String?,
      isOriginal: json['is_original'] as bool?,
      sourceType: json['source_type'] as String?,
    );

Map<String, dynamic> _$OtherLanguageEditionToJson(
        OtherLanguageEdition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lang': instance.lang,
      'title': instance.title,
      'source_id': instance.sourceId,
      'is_original': instance.isOriginal,
      'source_type': instance.sourceType,
    };
