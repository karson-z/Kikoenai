// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TranslationInfo _$TranslationInfoFromJson(Map<String, dynamic> json) =>
    TranslationInfo(
      lang: json['lang'] as String?,
      isChild: json['is_child'] as bool?,
      isParent: json['is_parent'] as bool?,
      isOriginal: json['is_original'] as bool?,
      isVolunteer: json['is_volunteer'] as bool?,
      childWorknos: (json['child_worknos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      parentWorkno: json['parent_workno'] as String?,
      originalWorkno: json['original_workno'] as String?,
      isTranslationAgree: json['is_translation_agree'] as bool?,
      translationBonusLangs: (json['translation_bonus_langs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isTranslationBonusChild: json['is_translation_bonus_child'] as bool?,
      translationStatusForTranslator:
          (json['translation_status_for_translator'] as Map<String, dynamic>?)
              ?.map(
        (k, e) =>
            MapEntry(k, TranslationStatus.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$TranslationInfoToJson(TranslationInfo instance) =>
    <String, dynamic>{
      'lang': instance.lang,
      'is_child': instance.isChild,
      'is_parent': instance.isParent,
      'is_original': instance.isOriginal,
      'is_volunteer': instance.isVolunteer,
      'child_worknos': instance.childWorknos,
      'parent_workno': instance.parentWorkno,
      'original_workno': instance.originalWorkno,
      'is_translation_agree': instance.isTranslationAgree,
      'translation_bonus_langs': instance.translationBonusLangs,
      'is_translation_bonus_child': instance.isTranslationBonusChild,
      'translation_status_for_translator':
          instance.translationStatusForTranslator,
    };
