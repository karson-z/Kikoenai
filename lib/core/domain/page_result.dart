import 'package:json_annotation/json_annotation.dart';

part 'page_result.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PageResult<T> {
  final List<T> records;
  final int total;
  final int size;
  final int current;
  final int pages;

  PageResult({
    required this.records,
    required this.total,
    required this.size,
    required this.current,
    required this.pages,
  });

  bool get hasNextPage => current < pages;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageResultFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PageResultToJson(this, toJsonT);
}
