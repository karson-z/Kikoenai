import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/service/site/site_api_provider.dart';

// 定义 Provider
final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
      () => SearchHistoryNotifier(),
    );

class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  CacheService get _service => CacheService.instance;

  @override
  FutureOr<List<String>> build() {
    final siteId = ref.watch(activeSiteIdProvider);
    return _service.getSearchHistory(siteId: siteId);
  }

  /// 添加历史记录
  Future<void> add(String keyword) async {
    final siteId = ref.read(activeSiteIdProvider);
    await _service.addSearchHistory(keyword, siteId: siteId);
    state = AsyncData(_service.getSearchHistory(siteId: siteId));
  }

  /// 删除单条
  Future<void> remove(String keyword) async {
    final siteId = ref.read(activeSiteIdProvider);
    await _service.removeSearchHistory(keyword, siteId: siteId);
    state = AsyncData(_service.getSearchHistory(siteId: siteId));
  }

  /// 清空
  Future<void> clear() async {
    final siteId = ref.read(activeSiteIdProvider);
    await _service.clearSearchHistory(siteId: siteId);
    state = const AsyncData([]);
  }
}
