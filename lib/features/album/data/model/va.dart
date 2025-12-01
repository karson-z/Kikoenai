import 'package:freezed_annotation/freezed_annotation.dart';

part 'va.g.dart';

@JsonSerializable()
class VA {
  final String? id;
  final String? name;
  final int? count; // 新增字段

  VA({this.id, this.name, this.count});

  factory VA.fromJson(Map<String, dynamic> json) => _$VAFromJson(json);
  Map<String, dynamic> toJson() => _$VAToJson(this);

  VA copyWith({String? id, String? name, int? count}) {
    return VA(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
    );
  }

  @override
  String toString() => 'VA(id: $id, name: $name, count: $count)';

  @override
  bool operator ==(Object other) =>
      other is VA &&
          other.id == id &&
          other.name == name &&
          other.count == count;

  @override
  int get hashCode => Object.hash(id, name, count);
}
