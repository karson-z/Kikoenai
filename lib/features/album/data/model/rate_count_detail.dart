import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';

part 'rate_count_detail.freezed.dart';
part 'rate_count_detail.g.dart';

@freezed
@HiveType(typeId: TypeIds.rateCountDetail, adapterName: 'RateCountDetailAdapter')
abstract class RateCountDetail with _$RateCountDetail {
  const factory RateCountDetail({
    @HiveField(0) @JsonKey(name: 'review_point') required int reviewPoint,
    @HiveField(1) required int count,
    @HiveField(2) required int ratio,
  }) = _RateCountDetail;

  factory RateCountDetail.fromJson(Map<String, dynamic> json) =>
      _$RateCountDetailFromJson(json);
}
