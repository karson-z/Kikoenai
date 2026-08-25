enum ReviewSortType {
  updatedAt('updated_at', '标记时间'),
  userRating('userRating', '评价'),
  release('release', '发布时间'),
  reviewCount('review_count', '评论数'),
  dlCount('dl_count', '售出数量'),
  nsfw('nsfw', '年龄分级');

  final String value;
  final String label;

  const ReviewSortType(this.value, this.label);

  /// 根据 API 字符串值查找对应的枚举
  /// 如果找不到，默认返回 [updatedAt]
  static ReviewSortType fromValue(String? value) {
    return ReviewSortType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => ReviewSortType.updatedAt,
    );
  }
}