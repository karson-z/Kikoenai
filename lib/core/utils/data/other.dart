import '../../../features/album/data/model/va.dart';

class OtherUtil{
  static String joinVAs(List<VA>? vas) {
    if (vas == null || vas.isEmpty) return '';
    // 过滤掉 name 为 null 或空字符串的项
    final names = vas.where((va) => va.name != null && va.name!.isNotEmpty).map((va) => va.name!.trim());
    return names.join('/');
  }
}