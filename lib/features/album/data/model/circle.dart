import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'circle.g.dart';

@JsonSerializable()
class Circle extends Equatable {
  final int id;

  @JsonKey(name: 'name')
  final String title;

  const Circle({required this.id, required this.title});

  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);
  Map<String, dynamic> toJson() => _$CircleToJson(this);

  @override
  List<Object?> get props => [id, title];
}
