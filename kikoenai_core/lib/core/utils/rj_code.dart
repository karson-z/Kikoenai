/// 从文件夹名中识别 DLsite RJ 编号。
///
/// 只看传入的名字，不看完整路径，也不看文件名。`RJ` 左边必须是开头或非字母数字，
/// 编号最多 10 位数字，前导零会被去掉。
class RjCode {
  static final RegExp _pattern = RegExp(
    r'(?:^|[^A-Za-z0-9])RJ0?(\d{1,10})(?!\d)',
    caseSensitive: false,
  );

  /// 返回名字里的第一个 RJ 编号。没有合法编号时返回 `null`。
  static int? parse(String name) {
    final match = _pattern.firstMatch(name);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  /// 返回名字里出现的全部 RJ 编号。
  static Set<int> parseAll(String name) {
    return _pattern
        .allMatches(name)
        .map((match) => int.tryParse(match.group(1) ?? ''))
        .whereType<int>()
        .toSet();
  }
}
