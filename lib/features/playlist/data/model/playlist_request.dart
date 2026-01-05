import 'package:kikoenai/core/enums/sort_options.dart';

import '../../../../core/model/search_tag.dart';

class PlaylistWorksRequest {
  final String id;
  final List<SearchTag> tags;
  final String textKeyword; // 普通搜索关键字
  final int page;
  final int pageSize;
  final bool includeTranslationWorks;
  final List<String> localSubtitledWorks;
  final SortOrder orderBy;
  final SortDirection sort;
  final bool subtitlesOnly;

  const PlaylistWorksRequest({
    required this.id,
    this.tags = const [],
    this.textKeyword = '',
    this.page = 1,
    this.pageSize = 12,
    this.includeTranslationWorks = true,
    this.localSubtitledWorks = const [],
    this.orderBy = SortOrder.createDate,
    this.sort = SortDirection.desc,
    this.subtitlesOnly = false,
  });

  /// 将对象转换为 API 需要的 JSON Map
  /// 核心：在这里自动合并 tags 和 keyword
  Map<String, dynamic> toJson() {
    // 1. 调用之前的工具方法进行合并
    final combinedKeyword = SearchTag.buildTagQueryPath(tags, keyword: textKeyword,encode: false);

    return {
      "id": id,
      "keyword": combinedKeyword, // 发送给后端的合并字符串
      "page": page,
      "pageSize": pageSize,
      "includeTranslationWorks": includeTranslationWorks,
      "localSubtitledWorks": localSubtitledWorks,
      "orderBy": orderBy.value,
      "sort": sort.value,
      "subtitlesOnly": subtitlesOnly,
    };
  }

  /// 复制方法 (用于修改部分参数，例如翻页)
  PlaylistWorksRequest copyWith({
    String? id,
    List<SearchTag>? tags,
    String? textKeyword,
    int? page,
    int? pageSize,
    bool? includeTranslationWorks,
    List<String>? localSubtitledWorks,
    SortOrder? orderBy,
    SortDirection? sort,
    bool? subtitlesOnly,
  }) {
    return PlaylistWorksRequest(
      id: id ?? this.id,
      tags: tags ?? this.tags,
      textKeyword: textKeyword ?? this.textKeyword,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      includeTranslationWorks: includeTranslationWorks ?? this.includeTranslationWorks,
      localSubtitledWorks: localSubtitledWorks ?? this.localSubtitledWorks,
      orderBy: orderBy ?? this.orderBy,
      sort: sort ?? this.sort,
      subtitlesOnly: subtitlesOnly ?? this.subtitlesOnly,
    );
  }
}