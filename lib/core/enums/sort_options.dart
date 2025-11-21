enum SortOrder {
  recommend('recommend','推荐'),
  createDate('create_date', '创建日期'),
  release('release', '发布日期'),
  rating('rate_average_2dp', '评分'),
  review('review_count', '评论数'),
  dlCount('dl_count', '销量'),
  price('price', '价格'),
  ;

  const SortOrder(this.value, this.label);

  final String value;
  final String label;

  /// 根据 label 拿到枚举
  static SortOrder? fromLabel(String label) {
    for (final item in SortOrder.values) {
      if (item.label == label) return item;
    }
    return null;
  }

  /// 根据 value 拿到枚举（顺便一起给你）
  static SortOrder? fromValue(String value) {
    for (final item in SortOrder.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum SortDirection {
  asc('asc', '升序'),
  desc('desc', '降序'),
  ;

  const SortDirection(this.value, this.label);

  final String value;
  final String label;

  static SortDirection fromValue(String value) {
    return SortDirection.values.firstWhere(
          (direction) => direction.value == value,
      orElse: () => SortDirection.desc,
    );
  }
}
