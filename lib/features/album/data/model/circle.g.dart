// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Circle _$CircleFromJson(Map<String, dynamic> json) => Circle(
      id: (json['id'] as num).toInt(),
      title: json['name'] as String,
    );

Map<String, dynamic> _$CircleToJson(Circle instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.title,
    };
