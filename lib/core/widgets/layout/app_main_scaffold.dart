import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:name_app/config/work_layout_config.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/core/common/navigation_item.dart';
import 'package:name_app/core/constants/app_constants.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:name_app/core/widgets/common/theme_toggle_button.dart';
import 'package:name_app/core/widgets/layout/navigation_rail.dart';
import 'package:provider/provider.dart';
import 'package:name_app/core/widgets/layout/adaptive_app_bar.dart';

/// 一个自适应的、响应式的脚手架，
/// 在小屏幕上显示 BottomNavigationBar，在大屏幕上显示 NavigationRail。
/// 大屏幕上，NavigationRail 会显示在左侧，BottomNavigationBar 会显示在底部。
/// 它使用 GoRouter 的状态作为唯一数据源，自动同步 UI。
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, this.child});

  final Widget? child;

  // 3. [优化] 自动从 GoRouter 状态计算当前索引
  int _calculateSelectedIndex(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final index = appNavigationItems.lastIndexWhere(
      // <-- 已修改
      (item) => path.startsWith(item.routePath),
    );
    return index == -1 ? 0 : index;
  }

  // 5. [修改] 使用 appNavigationItems
  void _navigateTo(BuildContext context, int index) {
    context.go(appNavigationItems[index].routePath); // <-- 已修改
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = WorkLayoutStrategy().getDeviceType(context);
    final int selectedIndex = _calculateSelectedIndex(context);
    final String title = appNavigationItems[selectedIndex].label;

    // 5. [优化] 使用 LayoutBuilder 来检测屏幕宽度并返回不同布局
    return LayoutBuilder(
      builder: (context, constraints) {
        // 定义断点

        if (deviceType == DeviceType.mobile) {
          // --- 移动端布局 (BottomNavigationBar) ---
          return Scaffold(
            body: child ?? Container(),
            bottomNavigationBar: _buildBottomNav(context, selectedIndex),
          );
        } else {
          // --- 桌面端布局 (NavigationRail) ---
          return Scaffold(
            body: Row(
              children: [
                AdaptiveNavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _navigateTo(context, index),
                ),
                Expanded(
                  child: Column(
                    children: [
                      AdaptiveAppBar(
                        title: Text(title),
                        automaticallyImplyLeading: false,
                        height: kToolbarHeight,
                      ),
                      Expanded(
                        child: child ?? Container(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // 辅助方法：构建 BottomNavigationBar
  Widget _buildBottomNav(BuildContext context, int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _navigateTo(context, index),
      // 动态生成导航项
      items: appNavigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: item.icon,
          label: item.label,
        );
      }).toList(),
      // 适配主题颜色
      type: BottomNavigationBarType.fixed, // 保证所有标签都显示
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
    );
  }
}
