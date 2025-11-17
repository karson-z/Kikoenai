import 'package:equatable/equatable.dart';
import '../../../data/model/work.dart';

class RecommendAndHotState extends Equatable {
  final List<Work> hotWorks;         // 热门作品
  final List<Work> recommendedWorks; // 推荐作品
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final int subtitleFilter; // 0: 全部, 1: 仅带字幕
  final int pageSize;       // 每页数量

  const RecommendAndHotState({
    this.hotWorks = const [],
    this.recommendedWorks = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.subtitleFilter = 0, // 默认显示全部
    this.pageSize = 30,      // 默认每页30条
  });

  RecommendAndHotState copyWith({
    List<Work>? hotWorks,
    List<Work>? recommendedWorks,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    int? subtitleFilter,
    int? pageSize,
  }) {
    return RecommendAndHotState(
      hotWorks: hotWorks ?? this.hotWorks,
      recommendedWorks: recommendedWorks ?? this.recommendedWorks,
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
    recommendedWorks,
    isLoading,
    error,
    currentPage,
    totalCount,
    hasMore,
    subtitleFilter,
    pageSize,
  ];
}
