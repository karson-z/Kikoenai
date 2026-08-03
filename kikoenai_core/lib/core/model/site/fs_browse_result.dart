import 'package:freezed_annotation/freezed_annotation.dart';

import 'fs_entry.dart';

part 'fs_browse_result.freezed.dart';
part 'fs_browse_result.g.dart';

/// 文件系统目录浏览结果。
///
/// 对应 `/api/fs/list` 返回的 `data` 对象，包含目录条目列表、
/// 总数、站点 / 目录说明（readme）及存储提供者等元信息。
@freezed
abstract class FsBrowseResult with _$FsBrowseResult {
  const factory FsBrowseResult({
    /// 当前页的目录条目
    @Default([]) List<FsEntry> content,

    /// 目录条目总数
    @Default(0) int total,

    /// 站点 / 目录说明（Markdown），无说明时为 null
    String? readme,

    /// 顶部说明（通常为空）
    @Default('') String header,

    /// 当前用户是否对该目录有写权限
    @Default(false) bool write,

    /// 存储提供者标识（如 `unknown` / `Onedrive`）
    @Default('unknown') String provider,
  }) = _FsBrowseResult;

  factory FsBrowseResult.fromJson(Map<String, dynamic> json) =>
      _$FsBrowseResultFromJson(json);
}
