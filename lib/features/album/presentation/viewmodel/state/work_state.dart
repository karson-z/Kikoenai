import 'package:equatable/equatable.dart';
import 'package:name_app/core/enums/sort_options.dart';

import '../../../data/model/work.dart';

class WorksState extends Equatable {
  final List<Work> works;
  final List<Work> hotWorks;         // 热门作品
  final List<Work> recommendedWorks; // 推荐作品
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final SortOrder sortOption;
  final SortDirection sortDirection;
  final int subtitleFilter; // 0: 全部, 1: 仅带字幕
  final int pageSize; // 每页数量
  final bool isLastPage; // 是否是最后一页(用于热门/推荐的100条限制提示)

  const WorksState({
    this.works = const [],
    this.hotWorks= const [],        // 热门作品
    this.recommendedWorks= const [], // 推荐作品
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.sortOption = SortOrder.createDate,
    this.sortDirection = SortDirection.desc,
    this.subtitleFilter = 0, // 默认显示全部
    this.pageSize = 20, // 全部模式每页30条
    this.isLastPage = false,
  });

  WorksState copyWith({
    List<Work>? works,
    List<Work>? hotWorks,       // 热门作品
    List<Work>? recommendedWorks,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    SortOrder? sortOption,
    SortDirection? sortDirection,
    int? subtitleFilter,
    int? pageSize,
    bool? isLastPage,
  }) {
    return WorksState(
      works: works ?? this.works,
      hotWorks: hotWorks ?? this.hotWorks,
      recommendedWorks: recommendedWorks ?? this.recommendedWorks,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
      pageSize: pageSize ?? this.pageSize,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }

  @override
  List<Object?> get props => [
    works,
    hotWorks,
    recommendedWorks,
    currentPage,
    totalCount,
    hasMore,
    sortOption,
    sortDirection,
    subtitleFilter,
    pageSize,
    isLastPage,
  ];
}