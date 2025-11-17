import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_edition.g.dart';
/// 语言版本
@JsonSerializable()
class LanguageEdition {
  final String? lang;
  final String? label;
  final String? workno;
  @JsonKey(name: 'edition_id')
  final int? editionId;
  @JsonKey(name: 'edition_type')
  final String? editionType;
  @JsonKey(name: 'display_order')
  final int? displayOrder;

  LanguageEdition({
    this.lang,
    this.label,
    this.workno,
    this.editionId,
    this.editionType,
    this.displayOrder,
  });

  factory LanguageEdition.fromJson(Map<String, dynamic> json) =>
      _$LanguageEditionFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageEditionToJson(this);

  LanguageEdition copyWith({
    String? lang,
    String? label,
    String? workno,
    int? editionId,
    String? editionType,
    int? displayOrder,
  }) {
    return LanguageEdition(
      lang: lang ?? this.lang,
      label: label ?? this.label,
      workno: workno ?? this.workno,
      editionId: editionId ?? this.editionId,
      editionType: editionType ?? this.editionType,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  String toString() =>
      'LanguageEdition(lang: $lang, label: $label, workno: $workno)';

  @override
  bool operator ==(Object other) =>
      other is LanguageEdition &&
          other.lang == lang &&
          other.label == label &&
          other.workno == workno &&
          other.editionId == editionId &&
          other.editionType == editionType &&
          other.displayOrder == displayOrder;

  @override
  int get hashCode =>
      Object.hash(lang, label, workno, editionId, editionType, displayOrder);
}