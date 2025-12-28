import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service/cache_service.dart';

// 定义 Provider
final searchHistoryProvider = AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
      () => SearchHistoryNotifier(),
);

class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  late final CacheService _cacheService;

  @override
  Future<List<String>> build() async {
    _cacheService = CacheService.instance;
    return await _cacheService.getSearchHistory();
  }

  /// 添加历史记录并刷新状态
  Future<void> add(String keyword) async {
    await _cacheService.addSearchHistory(keyword);
    // 重新加载数据以更新 UI
    state = AsyncData(await _cacheService.getSearchHistory());
  }

  /// 删除单条
  Future<void> remove(String keyword) async {
    await _cacheService.removeSearchHistory(keyword);
    state = AsyncData(await _cacheService.getSearchHistory());
  }

  /// 清空
  Future<void> clear() async {
    await _cacheService.clearSearchHistory();
    state = const AsyncData([]);
  }
}