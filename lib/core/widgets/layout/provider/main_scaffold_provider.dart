import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/colors_util.dart';

/// 全局 UI/Scaffold 状态模型
@immutable
class MainScaffoldState {
  // 播放页是否展开
  final bool isPlayerExpanded;
  // 全局导航栏是否显示
  final bool showBottomNav;
  // 播放器是否允许拖动
  final bool playerDraggable;

  // 动态主题颜色 (公有化以便于 Notifier 外部更新)
  final Color dominantColor;
  final Color vibrantColor;
  final Color mutedColor;


  const MainScaffoldState({
    this.isPlayerExpanded = false,
    this.showBottomNav = true,
    this.playerDraggable = true,
    this.dominantColor = Colors.transparent, // 默认值使用 Colors.transparent
    this.vibrantColor = Colors.transparent,  // 默认值使用 Colors.transparent
    this.mutedColor = Colors.transparent,    // 默认值使用 Colors.transparent
  });

  /// 修复并完善 copyWith 方法，确保所有字段都可被更新
  MainScaffoldState copyWith({
    bool? isPlayerExpanded,
    bool? showBottomNav,
    bool? playerDraggable,
    Color? dominantColor,
    Color? vibrantColor,
    Color? mutedColor,
  }) {
    return MainScaffoldState(
      isPlayerExpanded: isPlayerExpanded ?? this.isPlayerExpanded,
      showBottomNav: showBottomNav ?? this.showBottomNav,
      playerDraggable: playerDraggable ?? this.playerDraggable,
      dominantColor: dominantColor ?? this.dominantColor,
      vibrantColor: vibrantColor ?? this.vibrantColor,
      mutedColor: mutedColor ?? this.mutedColor,
    );
  }

  // 保持 == 和 hashCode 的实现，以确保 Riverpod 正确比较状态
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MainScaffoldState &&
        other.isPlayerExpanded == isPlayerExpanded &&
        other.showBottomNav == showBottomNav &&
        other.playerDraggable == playerDraggable &&
        other.dominantColor == dominantColor &&
        other.vibrantColor == vibrantColor &&
        other.mutedColor == mutedColor;
  }

  @override
  int get hashCode {
    return isPlayerExpanded.hashCode ^
    showBottomNav.hashCode ^
    playerDraggable.hashCode ^
    dominantColor.hashCode ^
    vibrantColor.hashCode ^
    mutedColor.hashCode;
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

  void setPlayerDraggable(bool draggable) => state = state.copyWith(playerDraggable: draggable);


  /// 新增：设置动态主题颜色的方法
  void setDominantColor(Color color) {
    state = state.copyWith(dominantColor: color);
  }

  /// 新增：设置动态主题颜色的方法
  void setVibrantColor(Color color) {
    state = state.copyWith(vibrantColor: color);
  }
  /// 异步方法：根据专辑封面 URL 提取颜色并更新全局状态
  Future<void> fetchAlbumColors(String albumImageUrl) async {
    // 检查 URL 是否为空，避免不必要的调用
    if (albumImageUrl.isEmpty) return;

    debugPrint('开始为 URL: $albumImageUrl 提取颜色...');
    try {
      // 1. 执行异步颜色提取 (类似于您原始的 _fetchAlbumColors)
      final colors = await ColorUtils.getMainColors(albumImageUrl);

      // 2. 更新状态 (在 Notifier 中，我们不需要检查 mounted，Riverpod 会处理生命周期)
      setDynamicColors(
        dominant: colors['dominant']!,
        vibrant: colors['vibrant']!,
        muted: colors['muted']!,

      );

      debugPrint('颜色提取成功，状态已更新。');

    } catch (e) {
      debugPrint('获取颜色失败: $e');
      // 错误处理: 可选地设置为默认颜色或透明
      setDynamicColors(
        dominant: Colors.white,
        vibrant: Colors.black54,
        muted: Colors.transparent,
      );
    }
  }
  /// 一次性设置主色和鲜艳色
  void setDynamicColors({required Color dominant, required Color vibrant,required Color muted}) {
    state = state.copyWith(
      dominantColor: dominant,
      vibrantColor: vibrant,
      mutedColor: muted,
    );
  }
}

final mainScaffoldProvider =
NotifierProvider<MainScaffoldNotifier, MainScaffoldState>(() => MainScaffoldNotifier());