import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'va.g.dart';

@JsonSerializable()
class Va extends Equatable {
  final String id;
  final String name;

  const Va({required this.id, required this.name});

  factory Va.fromJson(Map<String, dynamic> json) => _$VaFromJson(json);
  Map<String, dynamic> toJson() => _$VaToJson(this);

  @override
  List<Object?> get props => [id, name];
}
