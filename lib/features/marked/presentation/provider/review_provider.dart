import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

import '../../../../core/common/pagination.dart';
import '../../data/model/review_data.dart';
import '../../data/model/review_query_params.dart';
import '../../data/service/review_notifier.dart';
import '../../data/service/review_repository.dart';

final reviewParamsProvider = NotifierProvider<ReviewParamsNotifier, ReviewQueryParams>(() {
  return ReviewParamsNotifier();
});

final reviewListProvider = FutureProvider.autoDispose<PagedReviewData>((ref) async {
  final params = ref.watch(reviewParamsProvider);
  final service = ref.read(reviewServiceProvider);

  final jsonMap = await service.fetchReviews(params);
  final List<dynamic> listData = jsonMap.data?['works'] as List<dynamic>? ?? [];
  final works = listData
      .map((e) => Work.fromJson(e as Map<String, dynamic>))
      .toList();

  final pagination = Pagination.fromJson(jsonMap.data?['pagination']);
  return PagedReviewData(
    works: works,
    pagination: pagination,
  );
});
