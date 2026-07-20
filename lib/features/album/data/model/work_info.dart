import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';

part 'work_info.freezed.dart';
part 'work_info.g.dart';

@freezed
@HiveType(typeId: TypeIds.workInfo, adapterName: 'WorkInfoAdapter')
abstract class WorkInfo with _$WorkInfo {
  const factory WorkInfo({
    @HiveField(0) required int id,
    @HiveField(1) @JsonKey(name: 'source_type') String? sourceType,
    @HiveField(2) @JsonKey(name: 'source_id') String? sourceId,
  }) = _WorkInfo;

  factory WorkInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkInfoFromJson(json);
}
