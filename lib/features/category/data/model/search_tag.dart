class SearchTag {
  final String type;
  final String name;
  /// 是否排除
  final bool isExclude;

  const SearchTag(this.type, this.name, this.isExclude);

  @override
  String toString() {
    // 排除模式下形如 $-type:name$，非排除模式 $type:name$
    final prefix = isExclude ? "-$type" : type;
    return "\$$prefix:$name\$"; // 注意这里没有 {}
  }

}
