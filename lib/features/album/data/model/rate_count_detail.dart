import 'package:json_annotation/json_annotation.dart';

part 'rate_count_detail.g.dart';

@JsonSerializable()
class RateCountDetail {
  /// 评分等级，例如 1~5
  @JsonKey(name: 'review_point')
  final int reviewPoint;

  /// 给该等级评分的人数
  final int count;

  /// 占总评分人数的百分比（整数）
  final int ratio;

  RateCountDetail({
    required this.reviewPoint,
    required this.count,
    required this.ratio,
  });

  factory RateCountDetail.fromJson(Map<String, dynamic> json) =>
      _$RateCountDetailFromJson(json);

  Map<String, dynamic> toJson() => _$RateCountDetailToJson(this);

  @override
  String toString() =>
      'RateCountDetail(point: $reviewPoint, count: $count, ratio: $ratio)';
}
