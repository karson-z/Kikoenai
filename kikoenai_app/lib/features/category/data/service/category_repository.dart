
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

abstract class CategoryRepository {
  Future<Map<String,dynamic>> searchWorks({
    int page = 1,
    String? order,
    String? sort,
    int? subtitle,
    String? query,
    int? seed,
  });
  Future<List<dynamic>> getCircles();
  Future<List<dynamic>> getTags();
  Future<List<dynamic>> getVas();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final ApiClient api;

  CategoryRepositoryImpl(this.api);

  @override
  Future<Map<String, dynamic>> searchWorks({
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
    return api.get<Map<String, dynamic>>(
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
  }
  @override
  Future<List> getCircles() async {
    return api.get<List<dynamic>>(
      "/circles/",
    );
  }
  @override
  Future<List> getTags() async {
    return api.get<List<dynamic>>(
      "/tags/",
    );
  }
  @override
  Future<List> getVas() async {
    return api.get<List<dynamic>>(
      "/vas/",
    );
  }
}
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.read(apiClientProvider); // 从提供者拿 ApiClient
  return CategoryRepositoryImpl(apiClient);
});
