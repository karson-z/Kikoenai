// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'va.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VA _$VAFromJson(Map<String, dynamic> json) => VA(
      id: json['id'] as String?,
      name: json['name'] as String?,
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VAToJson(VA instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'count': instance.count,
    };
