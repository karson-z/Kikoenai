import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_works_request.freezed.dart';
part 'search_works_request.g.dart';

/// 作品搜索 / 推荐 / 热门请求的统一参数容器。
///
/// 不同站点实现按需读取自身关心的字段；未被站点支持的字段会被忽略。
/// [extra] 作为站点特有参数的逃生口，避免频繁修改接口签名。
@freezed
abstract class SearchWorksRequest with _$SearchWorksRequest {
  const factory SearchWorksRequest({
    /// 页码，从 1 开始
    @Default(1) int page,

    /// 每页数量
    @Default(20) int pageSize,

    /// 搜索关键字（空字符串视为不限制）
    String? keyword,

    /// 排序字段（站点自定义，如 create_date / release）
    String? order,

    /// 排序方向（asc / desc）
    String? sort,

    /// 字幕过滤（0 = 不限，1 = 仅字幕）
    int? subtitle,

    /// 随机种子（用于稳定随机排序）
    int? seed,

    /// 推荐器 UUID（仅推荐接口使用）
    String? recommenderUuid,

    /// 需要附带播放列表状态的 work id 列表
    List<String>? withPlaylistStatus,

    /// 是否包含翻译作品
    @Default(true) bool includeTranslationWorks,

    /// 本地字幕作品列表（用于服务端过滤）
    @Default([]) List<String> localSubtitledWorks,

    /// 站点特有参数逃生口
    @Default({}) Map<String, dynamic> extra,
  }) = _SearchWorksRequest;

  factory SearchWorksRequest.fromJson(Map<String, dynamic> json) =>
      _$SearchWorksRequestFromJson(json);
}
