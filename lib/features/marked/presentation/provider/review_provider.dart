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

  // 1. 获取完整 JSON
  final jsonMap = await service.fetchReviews(params);

  // 2. 解析列表 (假设列表在 'data' 字段中)
  final List<dynamic> listData = jsonMap.data?['works'] as List<dynamic>? ?? [];
  final works = listData
      .map((e) => Work.fromJson(e as Map<String, dynamic>))
      .toList();

  // 3. 解析分页信息 (直接把根 JSON 传进去解析，或者传 jsonMap['meta'] 取决于你的 API 结构)
  // 如果 currentPage 等字段在根目录下:
  final pagination = Pagination.fromJson(jsonMap.data?['pagination']);
  // 4. 返回组合对象
  return PagedReviewData(
    works: works,
    pagination: pagination,
  );
});
