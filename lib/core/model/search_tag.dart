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
  /// 构建标签查询字符串
  /// [tags] 标签列表
  /// [keyword] 搜索关键词
  /// [encode] 是否进行 Uri.encodeComponent 编码。
  ///          - GET 请求放在 URL 中时通常需要 true (默认)。
  ///          - POST 请求放在 JSON Body 中时通常需要 false。
  static String buildTagQueryPath(
      List<SearchTag> tags, {
        String? keyword,
        bool encode = true, // ✨ 新增开关，默认开启
      }) {
    final tagPath = tags.map((tag) {
      final prefix = tag.isExclude ? "-${tag.type}" : tag.type;
      final raw = "\$$prefix:${tag.name}\$";
      return encode ? Uri.encodeComponent(raw) : raw;
    }).join(' ');

    if (keyword != null && keyword.isNotEmpty) {
      final kw = encode ? Uri.encodeComponent(keyword) : keyword;

      // 注意：如果 tagPath 不为空，直接拼接可能会导致 "$tag:xx$keyword" 粘连。
      // 如果是为了 POST JSON 搜索（"$tag:xx$ keyword"），建议这里加个空格分隔。
      // 这里根据你之前的逻辑保持直接拼接，如果发现搜不到，请尝试改为:
      // return tagPath.isEmpty ? kw : '$tagPath $kw';
      return '$tagPath$kw';
    }

    return tagPath;
  }
}
