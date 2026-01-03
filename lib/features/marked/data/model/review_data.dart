import '../../../../core/common/pagination.dart';
import '../../../album/data/model/work.dart';

class PagedReviewData {
  final List<Work> works;
  final Pagination pagination;

  PagedReviewData({
    required this.works,
    required this.pagination,
  });
}