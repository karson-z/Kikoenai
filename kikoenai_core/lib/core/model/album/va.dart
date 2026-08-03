import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'va.freezed.dart';
part 'va.g.dart';

@freezed
@HiveType(typeId: TypeIds.va, adapterName: 'VAAdapter')
abstract class VA with _$VA {
  const factory VA({
    @HiveField(0) String? id,
    @HiveField(1) String? name,
    @HiveField(2) int? count,
  }) = _VA;

  factory VA.fromJson(Map<String, dynamic> json) => _$VAFromJson(json);
}
