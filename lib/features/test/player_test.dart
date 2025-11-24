import 'package:flutter/material.dart';

class GlobalPlayerPanel extends StatelessWidget {
  final Widget body;
  final bool isBottomNavVisible;
  final Widget? bottomNavWidget; // 新增属性，用于在播放器内显示 BottomNav

  const GlobalPlayerPanel({
    super.key,
    required this.body,
    required this.isBottomNavVisible,
    this.bottomNavWidget,
  });
  static const double kMiniPlayerHeight = 60.0;
// 底部导航栏高度 (保持与您代码中的 60 一致)
  static const double kBottomNavBarHeight = 60.0;
  // 最小播放器高度和导航栏高度
  static const double _playerHeight = kMiniPlayerHeight;

  @override
  Widget build(BuildContext context) {

    // 2. 内容区域的底部填充
    const double contentPadding = kMiniPlayerHeight;
    // 如果 BottomNav 可见，内容需要额外避开 BottomNav
    final double navBarOffset = isBottomNavVisible ? kBottomNavBarHeight : 0.0;

    // 为了简化，这里不使用 SlidingUpPanel，而是使用 Stack 模拟其占位原理
    // 实际项目中应使用 SlidingUpPanel
    return Stack(
      children: [
        // 内容体：应用总的底部填充
        Padding(
          padding: EdgeInsets.only(
              bottom: contentPadding + navBarOffset
          ),
          child: body,
        ),

        // 底部导航栏和播放器区域 (fixed position)
        // 导航栏位于最底部 (如果可见)
        if (isBottomNavVisible && bottomNavWidget != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: kBottomNavBarHeight,
            child: bottomNavWidget!,
          ),

        // 播放器位于导航栏上方或贴底
        Positioned(
          left: 0,
          right: 0,
          bottom: navBarOffset, // 动态调整位置
          height: _playerHeight,
          child: Container(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            child: const Center(child: Text("Global Mini Player")),
          ),
        ),
      ],
    );
  }
}