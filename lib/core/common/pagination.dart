import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pagination.g.dart';

@JsonSerializable()
class Pagination extends Equatable {
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
