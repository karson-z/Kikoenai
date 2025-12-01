import 'package:freezed_annotation/freezed_annotation.dart';
part 'tag.g.dart';
@JsonSerializable()
class Tag {
  final int? id;
  final String? name;
  final Map<String, dynamic>? i18n;
  final int? count; // 新增字段

  Tag({this.id, this.name, this.i18n, this.count});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);

  Tag copyWith({int? id, String? name, Map<String, dynamic>? i18n, int? count}) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      i18n: i18n ?? this.i18n,
      count: count ?? this.count,
    );
  }

  @override
  String toString() => 'Tag(id: $id, name: $name, count: $count)';

  @override
  bool operator ==(Object other) =>
      other is Tag &&
          other.id == id &&
          other.name == name &&
          other.i18n == i18n &&
          other.count == count;

  @override
  int get hashCode => Object.hash(id, name, i18n, count);
}
