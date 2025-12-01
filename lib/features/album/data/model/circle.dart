import 'package:freezed_annotation/freezed_annotation.dart';

part 'circle.g.dart';

@JsonSerializable()
class Circle {
  final int? id;
  final String? name;

  @JsonKey(name: 'source_id')
  final String? sourceId;

  @JsonKey(name: 'source_type')
  final String? sourceType;

  final int? count;

  Circle({
    this.id,
    this.name,
    this.sourceId,
    this.sourceType,
    this.count,
  });

  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);
  Map<String, dynamic> toJson() => _$CircleToJson(this);

  Circle copyWith({
    int? id,
    String? name,
    String? sourceId,
    String? sourceType,
    int? count,
  }) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      count: count ?? this.count,
    );
  }

  @override
  String toString() => 'Circle(id: $id, name: $name, count: $count)';

  @override
  bool operator ==(Object other) =>
      other is Circle &&
          other.id == id &&
          other.name == name &&
          other.sourceId == sourceId &&
          other.sourceType == sourceType &&
          other.count == count;

  @override
  int get hashCode => Object.hash(id, name, sourceId, sourceType, count);
}