/// 筛选维度分类（原 lib/core/widgets/filter/filter_silder_bar.dart 中的定义，
/// 随旧筛选弹层退役迁入 core）。
enum CategoryType {
  tag,
  circle,
  va,
  special,
}

extension CategoryTypeExtension on CategoryType {
  String get label {
    switch (this) {
      case CategoryType.tag:
        return '标签';
      case CategoryType.circle:
        return '社团';
      case CategoryType.va:
        return '声优';
      case CategoryType.special:
        return '特殊';
    }
  }
}
