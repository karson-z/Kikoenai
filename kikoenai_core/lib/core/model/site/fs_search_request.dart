import 'package:freezed_annotation/freezed_annotation.dart';

part 'fs_search_request.freezed.dart';
part 'fs_search_request.g.dart';

/// 文件系统搜索请求（Alist 风格 `/api/fs/search`）。
///
/// 用于 [SiteFeature.fileSystemSearch] 能力，按关键字跨目录递归搜索
/// 文件 / 目录名。对应请求体：
///
/// ```json
/// {
///   "parent": "/",
///   "keywords": "RJ299635",
///   "scope": 1,
///   "page": 1,
///   "per_page": 100,
///   "password": ""
/// }
/// ```
@freezed
abstract class FsSearchRequest with _$FsSearchRequest {
  const factory FsSearchRequest({
    /// 搜索的根目录（搜索范围会限制在该目录及其子目录下）
    @Default('/') String parent,

    /// 搜索关键字（如 RJ 号、作品名片段）
    required String keywords,

    /// 搜索范围
    ///
    /// - `0`：仅当前目录
    /// - `1`：递归子目录（默认，常用）
    @Default(1) int scope,

    /// 页码，从 1 开始
    @Default(1) int page,

    /// 每页数量（对应 Alist 的 `per_page`）
    @JsonKey(name: 'per_page') @Default(100) int perPage,

    /// 访问密码（受保护目录需要）
    @Default('') String password,

    /// 站点特有参数逃生口
    @Default({}) Map<String, dynamic> extra,
  }) = _FsSearchRequest;

  factory FsSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$FsSearchRequestFromJson(json);
}
