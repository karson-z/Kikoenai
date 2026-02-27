import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局 UI/Scaffold 状态模型
@immutable
class MainScaffoldState {
  // 播放页是否展开
  final bool isPlayerExpanded;
  // 全局导航栏是否显示
  final bool showBottomNav;



  const MainScaffoldState({
    this.isPlayerExpanded = false,
    this.showBottomNav = true,
  });

  /// 修复并完善 copyWith 方法，确保所有字段都可被更新
  MainScaffoldState copyWith({
    bool? isPlayerExpanded,
    bool? showBottomNav,
    bool? playerDraggable,
  }) {
    return MainScaffoldState(
      isPlayerExpanded: isPlayerExpanded ?? this.isPlayerExpanded,
      showBottomNav: showBottomNav ?? this.showBottomNav,
    );
  }

  // 保持 == 和 hashCode 的实现，以确保 Riverpod 正确比较状态
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MainScaffoldState &&
        other.isPlayerExpanded == isPlayerExpanded &&
        other.showBottomNav == showBottomNav;
  }

  @override
  int get hashCode {
    return isPlayerExpanded.hashCode ^
    showBottomNav.hashCode;
  }
}

/// 全局 UI 逻辑控制器
class MainScaffoldNotifier extends Notifier<MainScaffoldState> {
  @override
  MainScaffoldState build() {
    return const MainScaffoldState();
  }
  void expandPlayer() => state = state.copyWith(isPlayerExpanded: true);

  void collapsePlayer() => state = state.copyWith(isPlayerExpanded: false);

  void setBottomNav(bool visible) => state = state.copyWith(showBottomNav: visible);
}

final mainScaffoldProvider =
NotifierProvider<MainScaffoldNotifier, MainScaffoldState>(() => MainScaffoldNotifier());