import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kikoenai_core/core/model/album/work.dart';

part 'work_state.freezed.dart';

/// 作品列表的分页状态（Work 分页加载专用）。
///
/// 与 [Work] 一同放在 album 域下，方便 app 与 sites 两侧复用同一份状态结构。
@freezed
abstract class WorkState with _$WorkState {
  const factory WorkState({
    @Default([]) List<Work> works,
    @Default(1) int currentPage,
    @Default(0) int totalCount,
    @Default(true) bool hasMore,
    @Default(false) bool isLoading,
  }) = _WorkState;
}
