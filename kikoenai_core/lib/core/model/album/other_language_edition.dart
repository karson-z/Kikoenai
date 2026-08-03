import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'other_language_edition.freezed.dart';
part 'other_language_edition.g.dart';

/// 其他语言版本
@freezed
@HiveType(
  typeId: TypeIds.otherLanguageEdition,
  adapterName: 'OtherLanguageEditionAdapter',
)
abstract class OtherLanguageEdition with _$OtherLanguageEdition {
  const factory OtherLanguageEdition({
    @HiveField(0) int? id,
    @HiveField(1) String? lang,
    @HiveField(2) String? title,
    @HiveField(3) @JsonKey(name: 'source_id') String? sourceId,
    @HiveField(4) @JsonKey(name: 'is_original') bool? isOriginal,
    @HiveField(5) @JsonKey(name: 'source_type') String? sourceType,
  }) = _OtherLanguageEdition;

  factory OtherLanguageEdition.fromJson(Map<String, dynamic> json) =>
      _$OtherLanguageEditionFromJson(json);
}
