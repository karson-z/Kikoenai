import 'package:freezed_annotation/freezed_annotation.dart';

part 'va.g.dart';

@JsonSerializable()
class VA {
  final String? id;
  final String? name;

  VA({this.id, this.name});

  factory VA.fromJson(Map<String, dynamic> json) => _$VAFromJson(json);
  Map<String, dynamic> toJson() => _$VAToJson(this);

  VA copyWith({String? id, String? name}) {
    return VA(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  String toString() => 'VA(id: $id, name: $name)';

  @override
  bool operator ==(Object other) => other is VA && other.id == id && other.name == name;
  @override
  int get hashCode => Object.hash(id, name);
}