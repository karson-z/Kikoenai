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

  Circle({this.id, this.name, this.sourceId, this.sourceType});

  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);
  Map<String, dynamic> toJson() => _$CircleToJson(this);

  Circle copyWith({int? id, String? name, String? sourceId, String? sourceType}) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
    );
  }

  @override
  String toString() => 'Circle(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      other is Circle && other.id == id && other.name == name && other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(id, name, sourceId, sourceType);
}