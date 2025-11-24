import 'package:json_annotation/json_annotation.dart';

part 'work_info.g.dart';

@JsonSerializable()
class WorkInfo {
  final int id;

  @JsonKey(name: 'source_type')
  final String? sourceType;

  @JsonKey(name: 'source_id')
  final String? sourceId;

  const WorkInfo({
    required this.id,
    this.sourceType,
    this.sourceId,
  });

  /// JSON → WorkInfo
  factory WorkInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkInfoFromJson(json);

  /// WorkInfo → JSON
  Map<String, dynamic> toJson() => _$WorkInfoToJson(this);

  /// 可选的 copyWith（手写）
  WorkInfo copyWith({
    int? id,
    String? sourceType,
    String? sourceId,
  }) {
    return WorkInfo(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
