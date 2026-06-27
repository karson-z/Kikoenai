// works_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/model/work.dart';

part 'work_state.freezed.dart';

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
