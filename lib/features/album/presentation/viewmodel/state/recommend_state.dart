import 'package:equatable/equatable.dart';
import '../../../data/model/work.dart';

class RecommendState extends Equatable {
  final List<Work> recommendedWorks; // 推荐作品
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final int subtitleFilter; // 0: 全部, 1: 仅带字幕
  final int pageSize;       // 每页数量

  const RecommendState({
    this.recommendedWorks = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.subtitleFilter = 0, // 默认显示全部
    this.pageSize = 30,      // 默认每页30条
  });

  RecommendState copyWith({
    List<Work>? recommendedWorks,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    int? subtitleFilter,
    int? pageSize,
  }) {
    return RecommendState(
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
