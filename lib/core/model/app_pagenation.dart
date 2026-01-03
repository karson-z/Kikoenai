class Pagination {
  final int currentPage;
  final int pageSize;
  final int totalCount;

  Pagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      // 这里的 key 对应你提供的 JSON 字段
      currentPage: json['currentPage'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }
}

