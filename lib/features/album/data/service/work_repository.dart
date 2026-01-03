
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/user_work_status.dart';
import '../../../../core/common/result.dart';
import '../../../../core/enums/work_progress.dart';
import '../../../../core/utils/network/api_client.dart';

abstract class WorkRepository {
  Future<Result<Map<String,dynamic>>> getWorks({
    int page = 1,
    String? order,
    String? sort,
    int? subtitle,
    int? seed,
  });
  Future<Result<Map<String, dynamic>>> getPopularWorks({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    int? subtitle,
    List<String>? withPlaylistStatus,
  });
  Future<Result<Map<String, dynamic>>> getRecommendedWorks({
    String? recommenderUuid,
    int page = 1,
    int pageSize = 20,
    String? keyword,
    int? subtitle,
    List<String>? withPlaylistStatus,
  });
  Future<Result<List<dynamic>>> getWorkTracks(int workId);
  Future<Result<Map<String, dynamic>>>  getWorkDetail(int workId);
  Future<Result<Map<String, dynamic>>> getReviews(UserWorkStatus workStatus);
}

class WorkRepositoryImpl implements WorkRepository {
  final ApiClient api;

  WorkRepositoryImpl(this.api);

  @override
  Future<Result<Map<String, dynamic>>> getWorks({
    int page = 1,
    int pageSize = 20,
    String? order,
    String? sort,
    int? subtitle,
    int? seed,
  }) async {
    final response = await api.get<Map<String, dynamic>>(
      "/works",
      queryParameters: {
        "page": page,
        "pageSize": pageSize,
        if (order != null) "order": order,
        if (sort != null) "sort": sort,
        if (subtitle != null) "subtitle": subtitle,
        if (seed != null) "seed": seed,
      },
    );
    // ApiClient 已经返回 Result<Map<String,dynamic>>
    return response;
  }

  @override
  Future<Result<Map<String, dynamic>>> getPopularWorks({
    int page = 1,
    int pageSize = 30,
    String? keyword,
    int? subtitle,
    List<String>? withPlaylistStatus,
  }) async {
    final data = {
      'keyword': keyword ?? ' ',
      'page': page,
      'pageSize': pageSize,
      'subtitle': subtitle ?? 0,
      'localSubtitledWorks': [],
      'withPlaylistStatus': withPlaylistStatus ?? [],
    };
    final response = await api.post<Map<String, dynamic>>(
      '/recommender/popular',
      data: data,
    );
    return response;
  }

  @override
  Future<Result<Map<String, dynamic>>> getRecommendedWorks({
    String? recommenderUuid,
    int page = 1,
    int pageSize = 30,
    String? keyword,
    int? subtitle,
    List<String>? withPlaylistStatus,
  }) async {
    final data = {
      'keyword': keyword ?? ' ',
      'recommenderUuid': recommenderUuid ?? "172bd570-a894-475b-8a20-9241d0d314e8",
      'page': page,
      'pageSize': pageSize,
      'subtitle': subtitle ?? 0,
      'localSubtitledWorks': [],
      'withPlaylistStatus': withPlaylistStatus ?? [],
    };

    final response = await api.post<Map<String, dynamic>>(
      '/recommender/recommend-for-user',
      data: data,
    );
    return response;
  }

  @override
  Future<Result<List<dynamic>>> getWorkTracks(int workId) async {
    final data = {
      'v': 2,
    };
    final response = await api.get<List<dynamic>>('/tracks/$workId',queryParameters: data);
    return response;
  }

  @override
  Future<Result<Map<String, dynamic>>> getWorkDetail(int workId) async {
    final response = await api.get<Map<String, dynamic>>(
      '/work/$workId',
    );
    return response;
  }

  @override
  Future<Result<Map<String, dynamic>>> getReviews(UserWorkStatus workStatus) async {
    // 1. 创建一个可变的 Map，仅包含必填项 (例如 work_id)
    final Map<String, dynamic> requestData = {
      'work_id': workStatus.workId,
    };

    // 2. 动态添加字段：只有当 rating > 0 时才传
    if (workStatus.rating > 0) {
      requestData['rating'] = workStatus.rating;
    }

    // 3. 动态添加字段：只有当评论不为空时才传
    if (workStatus.reviewText.isNotEmpty) {
      requestData['review_text'] = workStatus.reviewText;
    }

    // 4. 动态添加字段：只有进度不是 unknown 时才传 (根据你的业务需求调整)
    if (workStatus.progress != WorkProgress.unknown) {
      requestData['progress'] = workStatus.progress.toJson(); // 使用枚举的 value
    }

    // 5. 发送请求
    // 注意：Dio 的 data 参数可以直接接收 Map，它会自动序列化为 JSON
    final response = await api.put<Map<String, dynamic>>(
      '/review',
      data: requestData,
    );

    return response;
  }
}
final workRepositoryProvider = Provider<WorkRepository>((ref) {
  final apiClient = ref.read(apiClientProvider); // 从提供者拿 ApiClient
  return WorkRepositoryImpl(apiClient);
});