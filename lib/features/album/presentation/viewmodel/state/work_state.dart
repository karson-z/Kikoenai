// works_state.dart
import 'package:equatable/equatable.dart';

import '../../../data/model/work.dart';

class WorkState extends Equatable {
  final List<Work> works;
  final int currentPage;
  final int totalCount;
  final bool hasMore;

  const WorkState({
    this.works = const [],
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
  });

  WorkState copyWith({
    List<Work>? works,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
  }) {
    return WorkState(
      works: works ?? this.works,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [works, currentPage, totalCount, hasMore];
}