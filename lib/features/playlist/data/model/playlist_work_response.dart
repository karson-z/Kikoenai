import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/common/pagination.dart';
import '../../../album/data/model/work.dart';
part 'playlist_work_response.freezed.dart';
part 'playlist_work_response.g.dart';
@freezed
sealed class PlaylistWorksResponse with _$PlaylistWorksResponse {
  const factory PlaylistWorksResponse({
    // 假设后端返回的 key 是 'works'，如果是 'list' 请修改 @JsonKey
    @Default([]) List<Work> works,

    // 复用之前的 Pagination 模型
    required Pagination pagination,
  }) = _PlaylistWorksResponse;

  factory PlaylistWorksResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaylistWorksResponseFromJson(json);
}