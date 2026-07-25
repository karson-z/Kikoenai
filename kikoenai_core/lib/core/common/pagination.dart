import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pagination.g.dart';

Object? _readCurrentPage(Map json, String key) {
  return json['currentPage'] ?? json['page'];
}

@JsonSerializable()
class Pagination extends Equatable {
  @JsonKey(readValue: _readCurrentPage)
  final int currentPage;

  final int pageSize;

  final int totalCount;

  const Pagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationToJson(this);

  @override
  List<Object?> get props => [currentPage, pageSize, totalCount];
}
