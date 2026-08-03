import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'circle.freezed.dart';
part 'circle.g.dart';

@freezed
@HiveType(typeId: TypeIds.circle, adapterName: 'CircleAdapter')
abstract class Circle with _$Circle {
  const factory Circle({
    @HiveField(0) int? id,
    @HiveField(1) String? name,
    @HiveField(2) @JsonKey(name: 'source_id') String? sourceId,
    @HiveField(3) @JsonKey(name: 'source_type') String? sourceType,
    @HiveField(4) int? count,
  }) = _Circle;

  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);
}
