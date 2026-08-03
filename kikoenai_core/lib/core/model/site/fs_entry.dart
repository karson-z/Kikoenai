import 'package:freezed_annotation/freezed_annotation.dart';

part 'fs_entry.freezed.dart';
part 'fs_entry.g.dart';

/// Alist 文件系统中的单个条目（文件或目录）。
///
/// 对应 `/api/fs/list` 返回的 `data.content[]` 数组项。
@freezed
abstract class FsEntry with _$FsEntry {
  const factory FsEntry({
    /// 名称
    required String name,

    /// 父目录路径
    ///
    /// `/api/fs/list` 不返回此字段（默认空串，由调用方通过请求路径推断）；
    /// `/api/fs/search` 的结果会携带此字段，便于直接定位条目完整路径。
    @Default('') String parent,

    /// 字节大小（目录为 0）
    @Default(0) int size,

    /// 是否为目录
    @JsonKey(name: 'is_dir') @Default(false) bool isDir,

    /// 修改时间（ISO8601）
    DateTime? modified,

    /// 创建时间（ISO8601）
    DateTime? created,

    /// 签名（用于带访问凭证的下载链接）
    @Default('') String sign,

    /// 缩略图 URL
    @Default('') String thumb,

    /// 类型标识（1 = 目录，其他 = 文件具体类型）
    @Default(0) int type,

    /// 哈希信息原始字符串（可能为字面量 `"null"`）
    @Default('') String hashinfo,

    /// 哈希信息对象（通常为 null）
    @JsonKey(name: 'hash_info') dynamic hashInfo,
  }) = _FsEntry;

  factory FsEntry.fromJson(Map<String, dynamic> json) =>
      _$FsEntryFromJson(json);
}
