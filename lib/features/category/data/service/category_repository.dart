
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/result.dart';
import '../../../../core/utils/network/api_client.dart';

abstract class CategoryRepository {
  Future<Result<Map<String,dynamic>>> searchWorks({
    int page = 1,
    String? order,
    String? sort,
    int? subtitle,
    String? query,
    int? seed,
  });
  Future<Result<List<dynamic>>> getCircles();
  Future<Result<List<dynamic>>> getTags();
  Future<Result<List<dynamic>>> getVas();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final ApiClient api;

  CategoryRepositoryImpl(this.api);

  @override
  Future<Result<Map<String, dynamic>>> searchWorks({
    int page = 1,
    int pageSize = 20,
    String? order,
    String? sort,
    String? query,
    bool includeTranslationWorks = true,
    int? subtitle,
    int? seed,
  }) async {
   final searchQuery = query != null ? '/$query' : '';
    final response = await api.get<Map<String, dynamic>>(
      "/search$searchQuery",
      queryParameters: {
        "page": page,
        "pageSize": pageSize,
        if (order != null) "order": order,
        if (sort != null) "sort": sort,
        if (subtitle != null) "subtitle": subtitle,
        if (seed != null) "seed": seed,
        "includeTranslationWorks" : includeTranslationWorks,
      },
    );
    // ApiClient 已经返回 Result<Map<String,dynamic>>
    return response;
  }
  @override
  Future<Result<List>> getCircles() async {
    final response = await api.get<List<dynamic>>(
      "/circles/",
    );
    return response;
  }
  @override
  Future<Result<List>> getTags() async {
    final response = await api.get<List<dynamic>>(
      "/tags/",
    );
    return response;
  }
  @override
  Future<Result<List>> getVas() async {
    final response = await api.get<List<dynamic>>(
      "/vas/",
    );
    return response;
  }
}
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.read(apiClientProvider); // 从提供者拿 ApiClient
  return CategoryRepositoryImpl(apiClient);
});