/// kikoenai_core: 跨 package 共享的核心常量、枚举、工具与数据模型。
///
/// 当前包含：
/// - [TypeIds] — Hive 持久化模型的全局唯一 TypeId 集中管理。
/// - `core/enums`    — 跨域通用枚举（work_progress、sort_options）。
/// - `core/common`   — 跨域通用结构（Pagination）。
/// - `core/utils`    — 跨域通用工具（OtherUtil 等）。
/// - `core/constants` — 跨域通用常量（FileExtensions / FileType）。
/// - `core/model`    — 跨域通用数据模型（按功能域划分目录）。
library;

// ---- Constants / TypeIds ----
export 'core/constants/type_ids.dart';
export 'core/constants/file_extensions.dart';

// ---- Enums ----
export 'core/enums/work_progress.dart';
export 'core/enums/sort_options.dart';

// ---- Common ----
export 'core/common/pagination.dart';
export 'core/common/paged_result.dart';

// ---- Utils ----
export 'core/utils/other.dart';

// ---- Models: shared ----
export 'core/model/shared/search_tag.dart';
export 'core/model/shared/filter_option_item.dart';
export 'core/model/shared/archive_entry.dart';

// ---- Models: album ----
export 'core/model/album/work.dart';
export 'core/model/album/work_info.dart';
export 'core/model/album/work_state.dart';
export 'core/model/album/circle.dart';
export 'core/model/album/va.dart';
export 'core/model/album/tag.dart';
export 'core/model/album/rank.dart';
export 'core/model/album/rate_count_detail.dart';
export 'core/model/album/other_language_edition.dart';
export 'core/model/album/translation_info.dart';
export 'core/model/album/translation_status.dart';
export 'core/model/album/search_works_request.dart';

// ---- Models: filter ----
export 'core/model/filter/filter_data_state.dart';
export 'core/model/filter/search_filter_state.dart';

// ---- Models: user ----
export 'core/model/user/user.dart';
export 'core/model/user/limit_work_info.dart';
export 'core/model/user/user_work_status.dart';
export 'core/model/user/auth_response.dart';
export 'core/model/user/login_params.dart';
export 'core/model/user/register_model.dart';

// ---- Models: playlist ----
export 'core/model/playlist/playlist.dart';
export 'core/model/playlist/playlist_request.dart';
export 'core/model/playlist/playlist_response.dart';
export 'core/model/playlist/playlist_status.dart';
export 'core/model/playlist/playlist_work_response.dart';

// ---- Models: marked ----
export 'core/model/marked/review_data.dart';
export 'core/model/marked/review_query_params.dart';

// ---- Models: category ----
export 'core/model/category/selector_item.dart';

// ---- Models: player ----
export 'core/model/player/playback_session.dart';
export 'core/model/player/playback_track_state.dart';
export 'core/model/player/player_state.dart';
export 'core/model/player/progress_state.dart';
export 'core/model/player/player_queue.dart';
export 'core/model/player/lyrics_match_state.dart';

// ---- Models: local_media ----
export 'core/model/local_media/file_node.dart';
export 'core/model/local_media/file_scanner_state.dart';
export 'core/model/local_media/scan_mode.dart';

// ---- Models: lyrics ----
export 'core/model/lyrics/lyric_model.dart';
export 'core/model/lyrics/lyrics_state.dart';

// ---- Models: history ----
export 'core/model/history/history_entry.dart';
