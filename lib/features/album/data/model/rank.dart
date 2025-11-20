import 'package:json_annotation/json_annotation.dart';

part 'rank.g.dart';

@JsonSerializable()
class Rank {
  final String term;
  final String category;
  final int rank;
  @JsonKey(name: 'rank_date')
  final String rankDate;

  Rank({
    required this.term,
    required this.category,
    required this.rank,
    required this.rankDate,
  });

  factory Rank.fromJson(Map<String, dynamic> json) => _$RankFromJson(json);
  Map<String, dynamic> toJson() => _$RankToJson(this);
}
