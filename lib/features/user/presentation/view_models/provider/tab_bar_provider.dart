import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/tab_bar_state.dart';

class TabBarNotifier extends Notifier<TabBarState> {
  @override
  TabBarState build() {
    // 初始状态
    return const TabBarState(
      currentIndex: 0,
      tabs: ["观看历史", "正在追", "准备追", "已追完"],
    );
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
    debugPrint('切换到 Tab: ${state.tabs[index]}');
  }
}

// Riverpod provider
final tabBarProvider = NotifierProvider<TabBarNotifier, TabBarState>(() => TabBarNotifier());
