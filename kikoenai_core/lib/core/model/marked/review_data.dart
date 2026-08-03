import 'package:kikoenai_core/core/common/pagination.dart';
import 'package:kikoenai_core/core/model/album/work.dart';

class PagedReviewData {
  final List<Work> works;
  final Pagination pagination;

  PagedReviewData({
    required this.works,
    required this.pagination,
  });
}