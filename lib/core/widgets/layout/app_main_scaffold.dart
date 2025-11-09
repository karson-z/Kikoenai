import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:name_app/core/common/navigation_item.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
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
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.themeMode == ThemeMode.dark;
    final int selectedIndex = _calculateSelectedIndex(context);
    final String title = appNavigationItems[selectedIndex].label;

    // 5. [优化] 使用 LayoutBuilder 来检测屏幕宽度并返回不同布局
    return LayoutBuilder(
      builder: (context, constraints) {
        // 定义断点
        const double mobileBreakpoint = 600;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          // --- 移动端布局 (BottomNavigationBar) ---
          return Scaffold(
            appBar: AdaptiveAppBar(
              title: Text(title),
              height: kToolbarHeight,
              actions: [
                _buildThemeToggleButton(themeVM, isDark),
              ],
            ),
            body: child, // 内容区
            bottomNavigationBar: _buildBottomNav(context, selectedIndex),
          );
        } else {
          // --- 桌面端布局 (NavigationRail) ---
          return Scaffold(
            body: Row(
              children: [
                _buildNavigationRail(context, selectedIndex, themeVM, isDark),
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

  // 辅助方法：构建暗黑模式切换按钮
  Widget _buildThemeToggleButton(ThemeViewModel themeVM, bool isDark) {
    return IconButton(
      tooltip: isDark ? '切换为浅色' : '切换为深色',
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      onPressed: () => themeVM.toggleLightDark(),
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

  // 辅助方法：构建 NavigationRail
  Widget _buildNavigationRail(
    BuildContext context,
    int selectedIndex,
    ThemeViewModel themeVM,
    bool isDark,
  ) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _navigateTo(context, index),
      labelType: NavigationRailLabelType.selected,
      leading: const Padding(padding: EdgeInsets.only(top: 30.0)),
      // 动态生成导航项
      destinations: appNavigationItems.map((item) {
        return NavigationRailDestination(
          icon: item.icon,
          label: Text(item.label),
        );
      }).toList(),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                _buildThemeToggleButton(themeVM, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
