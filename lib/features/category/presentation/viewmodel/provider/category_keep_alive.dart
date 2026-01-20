import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/enums/sort_options.dart';

class KeepAliveManager extends Notifier<List<SortOrder>> {
  @override
  List<SortOrder> build() => [];

  // 核心逻辑：LRU (Least Recently Used)
  void markAsActive(SortOrder order) {
    // 如果已经在列表中，先移除（为了把它移到最新的位置）
    // 如果列表超过2个，移除头部（最早的）
    final oldList = state.where((element) => element != order).toList();

    // 把当前的加到末尾（表示最新访问）
    oldList.add(order);

    // 如果超过 2 个，移除头部（最早访问的那个）
    if (oldList.length > 2) {
      oldList.removeAt(0);
    }

    state = oldList;
  }
}

// 2. 注册 Provider
final keepAliveManagerProvider = NotifierProvider<KeepAliveManager, List<SortOrder>>(KeepAliveManager.new);