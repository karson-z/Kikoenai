// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Circle _$CircleFromJson(Map<String, dynamic> json) => Circle(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      sourceId: json['source_id'] as String?,
      sourceType: json['source_type'] as String?,
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CircleToJson(Circle instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'source_id': instance.sourceId,
      'source_type': instance.sourceType,
      'count': instance.count,
    };
