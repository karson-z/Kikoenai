import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';

part 'rank.freezed.dart';
part 'rank.g.dart';

@freezed
@HiveType(typeId: TypeIds.rank, adapterName: 'RankAdapter')
abstract class Rank with _$Rank {
  const factory Rank({
    @HiveField(0) required String term,
    @HiveField(1) required String category,
    @HiveField(2) required int rank,
    @HiveField(3) @JsonKey(name: 'rank_date') required String rankDate,
  }) = _Rank;

  factory Rank.fromJson(Map<String, dynamic> json) => _$RankFromJson(json);
}
