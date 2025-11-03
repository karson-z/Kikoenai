import 'package:json_annotation/json_annotation.dart';

part 'author.g.dart'; // 自动生成的文件

@JsonSerializable()
class Author {
  final int id;
  final String name;
  final String? bio;
  final int? workCount;
  final String? avatar;
  final String? createdAt;
  final String? updatedAt;

  Author({
    required this.id,
    required this.name,
    this.bio,
    this.workCount,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  // fromJson 和 toJson 方法自动生成
  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}
