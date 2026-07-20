import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
@HiveType(typeId: TypeIds.tag, adapterName: 'TagAdapter')
abstract class Tag with _$Tag {
  const factory Tag({
    @HiveField(0) int? id,
    @HiveField(1) String? name,
    @HiveField(2) Map<String, dynamic>? i18n,
    @HiveField(3) int? count,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
