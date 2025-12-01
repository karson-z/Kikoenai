// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkInfo _$WorkInfoFromJson(Map<String, dynamic> json) => WorkInfo(
      id: (json['id'] as num).toInt(),
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
    );

Map<String, dynamic> _$WorkInfoToJson(WorkInfo instance) => <String, dynamic>{
      'id': instance.id,
      'source_type': instance.sourceType,
      'source_id': instance.sourceId,
    };
