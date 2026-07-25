import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/constants/app_constants.dart';

class SlidingNavigationBar extends StatelessWidget {
  /// 接收来自播放器的展开进度 (0.0 = 折叠, 1.0 = 完全展开)
  final ValueListenable<double> expandProgress;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SlidingNavigationBar({
    super.key,
    required this.expandProgress,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Widget bottomNavBar = NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      height: AppConstants.kAppBottomNavHeight,
      destinations: appNavigationItems
          .map((item) => NavigationDestination(
        icon: item.icon,
        label: item.label,
      ))
          .toList(),
    );

    // 使用 ValueListenableBuilder 监听拖拽进度
    return ValueListenableBuilder<double>(
      valueListenable: expandProgress,
      builder: (context, progress, child) {
        // 计算 Y 轴偏移量
        // 当 progress 为 0 时 (折叠)，偏移量为 0
        // 当 progress 为 1 时 (展开)，偏移量为导航栏的高度 (即完全被推出版面)
        final double offsetY = AppConstants.kAppBottomNavHeight * progress;

        return Transform.translate(
          // withMinimum(0) 的逻辑可以通过 clamp 或 max 来保证安全
          offset: Offset(0, offsetY.clamp(0.0, AppConstants.kAppBottomNavHeight)),
          child: child,
        );
      },
      // 将不随动画改变的 bottomNavBar 作为 child 传入，提升渲染性能
      child: bottomNavBar,
    );
  }
}