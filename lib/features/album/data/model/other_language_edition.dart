
import 'package:freezed_annotation/freezed_annotation.dart';

part 'other_language_edition.g.dart';
/// 其他语言版本
@JsonSerializable()
class OtherLanguageEdition {
  final int? id;
  final String? lang;
  final String? title;
  @JsonKey(name: 'source_id')
  final String? sourceId;
  @JsonKey(name: 'is_original')
  final bool? isOriginal;
  @JsonKey(name: 'source_type')
  final String? sourceType;

  OtherLanguageEdition({
    this.id,
    this.lang,
    this.title,
    this.sourceId,
    this.isOriginal,
    this.sourceType,
  });

  factory OtherLanguageEdition.fromJson(Map<String, dynamic> json) =>
      _$OtherLanguageEditionFromJson(json);
  Map<String, dynamic> toJson() => _$OtherLanguageEditionToJson(this);

  OtherLanguageEdition copyWith({
    int? id,
    String? lang,
    String? title,
    String? sourceId,
    bool? isOriginal,
    String? sourceType,
  }) {
    return OtherLanguageEdition(
      id: id ?? this.id,
      lang: lang ?? this.lang,
      title: title ?? this.title,
      sourceId: sourceId ?? this.sourceId,
      isOriginal: isOriginal ?? this.isOriginal,
      sourceType: sourceType ?? this.sourceType,
    );
  }

  @override
  String toString() =>
      'OtherLanguageEdition(id: $id, lang: $lang, title: $title)';

  @override
  bool operator ==(Object other) =>
      other is OtherLanguageEdition &&
          other.id == id &&
          other.lang == lang &&
          other.title == title &&
          other.sourceId == sourceId &&
          other.isOriginal == isOriginal &&
          other.sourceType == sourceType;

  @override
  int get hashCode =>
      Object.hash(id, lang, title, sourceId, isOriginal, sourceType);
}