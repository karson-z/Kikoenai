import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../features/album/data/model/work.dart';

part 'filter_data_state.freezed.dart';

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