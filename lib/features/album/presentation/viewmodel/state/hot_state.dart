import 'package:equatable/equatable.dart';
import '../../../data/model/work.dart';

class HotState extends Equatable {
  final List<Work> hotWorks;         // 热门作品
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final int subtitleFilter; // 0: 全部, 1: 仅带字幕
  final int pageSize;       // 每页数量

  const HotState({
    this.hotWorks = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.subtitleFilter = 0, // 默认显示全部
    this.pageSize = 30,      // 默认每页30条
  });

  HotState copyWith({
    List<Work>? hotWorks,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    int? subtitleFilter,
    int? pageSize,
  }) {
    return HotState(
      hotWorks: hotWorks ?? this.hotWorks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
    hotWorks,
    isLoading,
    error,
    currentPage,
    totalCount,
    hasMore,
    subtitleFilter,
    pageSize,
  ];
}
