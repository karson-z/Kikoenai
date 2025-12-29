import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/circle.dart';
import 'package:kikoenai/features/album/data/model/tag.dart';
import 'package:kikoenai/features/album/data/model/va.dart';
import 'package:kikoenai/features/category/data/service/category_repository.dart';
import '../../../../../core/common/result.dart';
import '../../../../../core/service/cache_service.dart';


final circlesProvider = FutureProvider<List<Circle>>((ref) {
  return _fetchAndCache<Circle>(
    ref: ref,
    // 缓存读取回调
    getFromCache: () => CacheService.instance.getCirclesOption(),
    // 缓存保存回调
    saveToCache: (data) => CacheService.instance.saveCirclesOption(data),
    // API 请求回调
    getFromApi: (repo) => repo.getCircles(),
    // JSON 转换工厂
    fromJson: Circle.fromJson,
    // 对象转 JSON 回调
    toJson: (item) => item.toJson(),
    // 排序依据 (count)
    getCount: (item) => item.count,
  );
});

final vasProvider = FutureProvider<List<VA>>((ref) {
  return _fetchAndCache<VA>(
    ref: ref,
    getFromCache: () => CacheService.instance.getVasOption(),
    saveToCache: (data) => CacheService.instance.saveVasOption(data),
    getFromApi: (repo) => repo.getVas(),
    fromJson: VA.fromJson,
    toJson: (item) => item.toJson(),
    getCount: (item) => item.count,
  );
});

final tagsProvider = FutureProvider<List<Tag>>((ref) {
  return _fetchAndCache<Tag>(
    ref: ref,
    getFromCache: () => CacheService.instance.getTagsOption(),
    saveToCache: (data) => CacheService.instance.saveTagsOption(data),
    getFromApi: (repo) => repo.getTags(),
    fromJson: Tag.fromJson,
    toJson: (item) => item.toJson(),
    getCount: (item) => item.count,
  );
});

// ======================= 核心泛型逻辑 =======================

/// 一个通用的 "缓存优先 -> API -> 排序 -> 存缓存" 处理函数
Future<List<T>> _fetchAndCache<T>({
  required Ref ref,
  // 缓存获取方法：返回 List<Map> 或 null
  required Future<List<Map<String, dynamic>>?> Function() getFromCache,
  // 缓存保存方法
  required Future<void> Function(List<Map<String, dynamic>>) saveToCache,
  // API 获取方法：这里假设 repo 返回的是 Result<List<dynamic>> 或类似结构
  required Future<Result<List<dynamic>>> Function(CategoryRepository) getFromApi,
  // 反序列化方法
  required T Function(Map<String, dynamic>) fromJson,
  // 序列化方法
  required Map<String, dynamic> Function(T) toJson,
  // 获取排序字段 (count)
  required int? Function(T) getCount,
}) async {

  // 1. 尝试从缓存读取
  try {
    final cached = await getFromCache();
    if (cached != null && cached.isNotEmpty) {
      final list = cached.map(fromJson).toList();
      // 统一排序：按 count 倒序
      list.sort((a, b) => (getCount(b) ?? 0).compareTo(getCount(a) ?? 0));
      return list;
    }
  } catch (e) {
    // 缓存读取出错不应阻断流程，打印日志后继续走 API
    print('Cache read failed: $e');
  }

  // 2. 缓存未命中，请求 API
  final repository = ref.read(categoryRepositoryProvider);
  final res = await getFromApi(repository);

  // 数据清洗
  final list = res.data?.map((c) => fromJson(c as Map<String, dynamic>)).toList() ?? [];

  // 3. 排序
  list.sort((a, b) => (getCount(b) ?? 0).compareTo(getCount(a) ?? 0));

  try {
    await saveToCache(list.map(toJson).toList());
  } catch (e) {
    print('Cache save failed: $e');
  }

  return list;
}