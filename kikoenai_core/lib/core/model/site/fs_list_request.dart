import 'package:freezed_annotation/freezed_annotation.dart';

part 'fs_list_request.freezed.dart';
part 'fs_list_request.g.dart';

/// 文件系统目录浏览请求（Alist 风格 `/api/fs/list`）。
///
/// 用于 [SiteFeature.fileSystemBrowse] 能力，按路径分页列出目录内容。
/// 对应请求体：
///
/// ```json
/// { "path": "/", "password": "", "page": 1, "per_page": 30, "refresh": false }
/// ```
@freezed
abstract class FsListRequest with _$FsListRequest {
  const factory FsListRequest({
    /// 目录路径，根目录为 `/`
    @Default('/') String path,

    /// 访问密码（受保护目录需要）
    @Default('') String password,

    /// 页码，从 1 开始
    @Default(1) int page,

    /// 每页数量（对应 Alist 的 `per_page`）
    @JsonKey(name: 'per_page') @Default(30) int perPage,

    /// 是否强制刷新（跳过服务端缓存）
    @Default(false) bool refresh,

    /// 站点特有参数逃生口
    @Default({}) Map<String, dynamic> extra,
  }) = _FsListRequest;

  factory FsListRequest.fromJson(Map<String, dynamic> json) =>
      _$FsListRequestFromJson(json);
}
