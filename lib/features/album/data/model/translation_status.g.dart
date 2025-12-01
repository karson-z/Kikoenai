// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TranslationStatus _$TranslationStatusFromJson(Map<String, dynamic> json) =>
    TranslationStatus(
      isDenied: json['is_denied'] as bool,
      bonusPrice: (json['bonus_price'] as num).toInt(),
      isAvailable: json['is_available'] as bool,
      appliedCount: (json['applied_count'] as num).toInt(),
      onSaleCount: (json['on_sale_count'] as num).toInt(),
    );

Map<String, dynamic> _$TranslationStatusToJson(TranslationStatus instance) =>
    <String, dynamic>{
      'is_denied': instance.isDenied,
      'bonus_price': instance.bonusPrice,
      'is_available': instance.isAvailable,
      'applied_count': instance.appliedCount,
      'on_sale_count': instance.onSaleCount,
    };
