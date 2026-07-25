import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai_core/core/common/pagination.dart';
import 'package:kikoenai_core/core/model/playlist/playlist.dart';
part 'playlist_response.freezed.dart';
part 'playlist_response.g.dart';

@freezed
 abstract class PlaylistListResponse with _$PlaylistListResponse {
  const factory PlaylistListResponse({
    @Default([]) List<Playlist> playlists,

    // 分页信息
    required Pagination pagination,
  }) = _PlaylistListResponse;

  factory PlaylistListResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaylistListResponseFromJson(json);
}