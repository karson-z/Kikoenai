import '../../../../album/data/model/work.dart';

class CategoryState {
  final List<Work> works;
  final int currentPage;
  final int totalCount;
  final bool hasMore;



  const CategoryState({
    this.works = const [],
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
  });

  CategoryState copyWith({
    List<Work>? works,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
  }) {
    return CategoryState(
      works: works ?? this.works,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}