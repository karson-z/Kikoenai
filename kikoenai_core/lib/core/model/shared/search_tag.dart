import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'search_tag.g.dart';

@HiveType(typeId: TypeIds.searchTag)
class SearchTag {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final String name;

  /// 是否排除
  @HiveField(2)
  final bool isExclude;

  const SearchTag(this.type, this.name, this.isExclude);

  @override
  String toString() {
    final prefix = isExclude ? "-$type" : type;
    return "\$$prefix:$name\$";
  }

  static String buildTagQueryPath(
      List<SearchTag> tags, {
        String? keyword,
        bool encode = true,
      }) {
    final tagPath = tags.map((tag) {
      final prefix = tag.isExclude ? "-${tag.type}" : tag.type;
      final raw = "\$$prefix:${tag.name}\$";
      return encode ? Uri.encodeComponent(raw) : raw;
    }).join(' ');

    if (keyword != null && keyword.isNotEmpty) {
      final kw = encode ? Uri.encodeComponent(keyword) : keyword;
      return '$tagPath$kw';
    }

    return tagPath;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchTag &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              name == other.name &&
              isExclude == other.isExclude;

  @override
  int get hashCode => type.hashCode ^ name.hashCode ^ isExclude.hashCode;
}