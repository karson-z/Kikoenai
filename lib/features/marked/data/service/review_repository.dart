import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/result.dart';

import '../../../../core/utils/network/api_client.dart';
import '../model/review_query_params.dart';

abstract class ReviewService {
  Future<Result<Map<String, dynamic>>> fetchReviews(ReviewQueryParams params);
}
class ReviewServiceImpl implements ReviewService {
  final ApiClient api;

  ReviewServiceImpl(this.api);

  @override
  Future<Result<Map<String, dynamic>>> fetchReviews(ReviewQueryParams params) async {
    final queryMap = <String, dynamic>{
      'order': params.order,
      'sort': params.sort,
      'page': params.page,
      'filter': params.filter,
    };

    queryMap.removeWhere((key, value) => value == null);
    final response = await api.get<Map<String, dynamic>>(
      '/review',
      queryParameters: queryMap,
    );
    return response;
  }
}
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ReviewServiceImpl(apiClient);
});