import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/service/cache/cache_service.dart';

// 定义 Provider
final searchHistoryProvider = AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
      () => SearchHistoryNotifier(),
);

class SearchHistoryNotifier extends AsyncNotifier<List<String>> {

  CacheService get _service => CacheService.instance;

  @override
  FutureOr<List<String>> build() {
    return _service.getSearchHistory();
  }

  /// 添加历史记录
  Future<void> add(String keyword) async {
    await _service.addSearchHistory(keyword);
    state = AsyncData(_service.getSearchHistory());
  }

  /// 删除单条
  Future<void> remove(String keyword) async {
    await _service.removeSearchHistory(keyword);
    state = AsyncData(_service.getSearchHistory());
  }

  /// 清空
  Future<void> clear() async {
    await _service.clearSearchHistory();
    state = const AsyncData([]);
  }
}