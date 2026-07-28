import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../../core/service/cache/cache_service.dart';
import '../../../../../core/service/site/site_api_provider.dart';

final circlesProvider = FutureProvider.autoDispose<List<Circle>>((ref) {
  final siteId = ref.watch(activeSiteIdProvider);
  return _fetchAndCache<Circle>(
    ref: ref,
    feature: SiteFeature.circles,
    // 缓存读取回调
    getFromCache: () => CacheService.instance.getCirclesOption(siteId: siteId),
    // 缓存保存回调
    saveToCache: (data) =>
        CacheService.instance.saveCirclesOption(data, siteId: siteId),
    // API 请求回调（直接返回强类型 List<Circle>）
    getFromApi: (api) => api.getCircles(),
    // JSON 转换工厂（用于缓存读取反序列化）
    fromJson: Circle.fromJson,
    // 对象转 JSON 回调
    toJson: (item) => item.toJson(),
    // 排序依据 (count)
    getCount: (item) => item.count,
  );
});

final vasProvider = FutureProvider.autoDispose<List<VA>>((ref) {
  final siteId = ref.watch(activeSiteIdProvider);
  return _fetchAndCache<VA>(
    ref: ref,
    feature: SiteFeature.vas,
    getFromCache: () => CacheService.instance.getVasOption(siteId: siteId),
    saveToCache: (data) =>
        CacheService.instance.saveVasOption(data, siteId: siteId),
    getFromApi: (api) => api.getVas(),
    fromJson: VA.fromJson,
    toJson: (item) => item.toJson(),
    getCount: (item) => item.count,
  );
});

final tagsProvider = FutureProvider.autoDispose<List<Tag>>((ref) {
  final siteId = ref.watch(activeSiteIdProvider);
  return _fetchAndCache<Tag>(
    ref: ref,
    feature: SiteFeature.tags,
    getFromCache: () => CacheService.instance.getTagsOption(siteId: siteId),
    saveToCache: (data) =>
        CacheService.instance.saveTagsOption(data, siteId: siteId),
    getFromApi: (api) => api.getTags(),
    fromJson: Tag.fromJson,
    toJson: (item) => item.toJson(),
    getCount: (item) => item.count,
  );
});

/// 一个通用的 "缓存优先 -> API -> 排序 -> 存缓存" 处理函数
Future<List<T>> _fetchAndCache<T>({
  required Ref ref,
  required SiteFeature feature,
  // 缓存获取方法：返回 List<Map> 或 null
  required Future<List<Map<String, dynamic>>?> Function() getFromCache,
  // 缓存保存方法
  required Future<void> Function(List<Map<String, dynamic>>) saveToCache,
  // API 获取方法：直接返回强类型 List<T>
  required Future<List<T>> Function(SiteApi) getFromApi,
  // 反序列化方法（用于缓存读取）
  required T Function(Map<String, dynamic>) fromJson,
  // 序列化方法
  required Map<String, dynamic> Function(T) toJson,
  // 获取排序字段 (count)
  required int? Function(T) getCount,
}) async {
  final api = ref.read(activeSiteApiProvider);
  if (!api.supports(feature)) return const [];

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

  // 2. 缓存未命中，请求 API（直接返回强类型 List<T>，无需 map）
  final list = await getFromApi(api);

  // 3. 排序
  list.sort((a, b) => (getCount(b) ?? 0).compareTo(getCount(a) ?? 0));

  try {
    await saveToCache(list.map(toJson).toList());
  } catch (e) {
    print('Cache save failed: $e');
  }

  return list;
}
