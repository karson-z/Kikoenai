// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_count_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RateCountDetail _$RateCountDetailFromJson(Map<String, dynamic> json) =>
    RateCountDetail(
      reviewPoint: (json['review_point'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      ratio: (json['ratio'] as num).toInt(),
    );

Map<String, dynamic> _$RateCountDetailToJson(RateCountDetail instance) =>
    <String, dynamic>{
      'review_point': instance.reviewPoint,
      'count': instance.count,
      'ratio': instance.ratio,
    };
