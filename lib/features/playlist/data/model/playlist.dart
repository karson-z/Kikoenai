import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
sealed class Playlist with _$Playlist {
  const factory Playlist({
    required String id,

    // 修复 1: 加上 @JsonKey 映射 JSON 中的 user_name
    // 修复 2: 加默认值，防止 null 导致 crash
    @JsonKey(name: 'user_name') @Default('') String userName,

    // 隐私状态，0 通常代表公开
    @Default(0) int privacy,

    @Default('zh-CN') String locale,

    // 修复: 映射 playback_count
    @JsonKey(name: 'playback_count') @Default(0) int playbackCount,

    @Default('') String name,

    @Default('') String description,

    // 修复 3: 时间字段改为可空 (DateTime?)，并映射 created_at
    // 因为解析失败或字段为空时，required DateTime 会直接炸掉
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,

    // 修复: 映射 works_count
    @JsonKey(name: 'works_count') @Default(0) int worksCount,

    // 修复: 映射 latestWorkID (注意 JSON 里的 ID 是大写)
    @JsonKey(name: 'latestWorkID') int? latestWorkId,

    String? mainCoverUrl,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}