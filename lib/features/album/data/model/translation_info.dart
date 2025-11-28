import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai/features/album/data/model/translation_status.dart';
part 'translation_info.g.dart';
@JsonSerializable()
class TranslationInfo {
  final String? lang;
  @JsonKey(name: 'is_child')
  final bool? isChild;
  @JsonKey(name: 'is_parent')
  final bool? isParent;
  @JsonKey(name: 'is_original')
  final bool? isOriginal;
  @JsonKey(name: 'is_volunteer')
  final bool? isVolunteer;
  @JsonKey(name: 'child_worknos')
  final List<String>? childWorknos;
  @JsonKey(name: 'parent_workno')
  final String? parentWorkno;
  @JsonKey(name: 'original_workno')
  final String? originalWorkno;
  @JsonKey(name: 'is_translation_agree')
  final bool? isTranslationAgree;
  @JsonKey(name: 'translation_bonus_langs')
  final List<String>? translationBonusLangs;
  @JsonKey(name: 'is_translation_bonus_child')
  final bool? isTranslationBonusChild;
  @JsonKey(
    name: 'translation_status_for_translator',
  )
  final Map<String, TranslationStatus>? translationStatusForTranslator;

  TranslationInfo({
    this.lang,
    this.isChild,
    this.isParent,
    this.isOriginal,
    this.isVolunteer,
    this.childWorknos,
    this.parentWorkno,
    this.originalWorkno,
    this.isTranslationAgree,
    this.translationBonusLangs,
    this.isTranslationBonusChild,
    this.translationStatusForTranslator,
  });

  factory TranslationInfo.fromJson(Map<String, dynamic> json) =>
      _$TranslationInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TranslationInfoToJson(this);

  TranslationInfo copyWith({
    String? lang,
    bool? isChild,
    bool? isParent,
    bool? isOriginal,
    bool? isVolunteer,
    List<String>? childWorknos,
    String? parentWorkno,
    String? originalWorkno,
    bool? isTranslationAgree,
    List<String>? translationBonusLangs,
    bool? isTranslationBonusChild,
    Map<String, TranslationStatus>? translationStatusForTranslator,
  }) {
    return TranslationInfo(
      lang: lang ?? this.lang,
      isChild: isChild ?? this.isChild,
      isParent: isParent ?? this.isParent,
      isOriginal: isOriginal ?? this.isOriginal,
      isVolunteer: isVolunteer ?? this.isVolunteer,
      childWorknos: childWorknos ?? this.childWorknos,
      parentWorkno: parentWorkno ?? this.parentWorkno,
      originalWorkno: originalWorkno ?? this.originalWorkno,
      isTranslationAgree: isTranslationAgree ?? this.isTranslationAgree,
      translationBonusLangs: translationBonusLangs ?? this.translationBonusLangs,
      isTranslationBonusChild: isTranslationBonusChild ?? this.isTranslationBonusChild,
      translationStatusForTranslator: translationStatusForTranslator ?? this.translationStatusForTranslator,
    );
  }

  @override
  String toString() =>
      'TranslationInfo(lang: $lang, isChild: $isChild, isParent: $isParent)';

  @override
  bool operator ==(Object other) =>
      other is TranslationInfo &&
          other.lang == lang &&
          other.isChild == isChild &&
          other.isParent == isParent &&
          other.isOriginal == isOriginal &&
          other.isVolunteer == isVolunteer &&
          other.childWorknos == childWorknos &&
          other.parentWorkno == parentWorkno &&
          other.originalWorkno == originalWorkno &&
          other.isTranslationAgree == isTranslationAgree;

  @override
  int get hashCode => Object.hash(
      lang,
      isChild,
      isParent,
      isOriginal,
      isVolunteer,
      childWorknos,
      parentWorkno,
      originalWorkno,
      isTranslationAgree);
}