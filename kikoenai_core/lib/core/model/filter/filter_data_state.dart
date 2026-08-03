import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'filter_data_state.freezed.dart';

/// 筛选 / 分类页作品列表数据状态。
///
/// 与 [WorkState] 结构相同，但语义上属于筛选结果，便于在 app / sites 两侧复用。
@freezed
abstract class FilterDataState with _$FilterDataState {
  const factory FilterDataState({
    @Default([]) List<Work> works,
    @Default(1) int currentPage,
    @Default(0) int totalCount,
    @Default(true) bool hasMore,
    @Default(false) bool isLoading,
  }) = _FilterDataState;
}
