import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai_core/core/common/pagination.dart';
import 'package:kikoenai_core/core/model/album/work.dart';
part 'playlist_work_response.freezed.dart';
part 'playlist_work_response.g.dart';
@freezed
sealed class PlaylistWorksResponse with _$PlaylistWorksResponse {
  const factory PlaylistWorksResponse({
    @Default([]) List<Work> works,
    required Pagination pagination,
  }) = _PlaylistWorksResponse;

  factory PlaylistWorksResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaylistWorksResponseFromJson(json);
}