import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:name_app/config/navigation_item.dart';
import 'package:name_app/core/constants/app_constants.dart';
import 'package:name_app/core/widgets/layout/navigation_rail.dart';
import 'package:name_app/core/widgets/layout/adaptive_app_bar.dart';



class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, this.child});

  final Widget? child;

  /// 计算当前选中的索引
  int _calculateSelectedIndex(BuildContext context) {
    // 使用 GoRouterState 获取当前路由位置
    final String location = GoRouterState.of(context).uri.path;

    // 使用 lastIndexWhere 确保匹配最具体的路由
    // 例如：/works/detail 会匹配 /works 而不是 /home
    final index = appNavigationItems.lastIndexWhere(
          (item) => location.startsWith(item.routePath),
    );

    return index == -1 ? 0 : index;
  }

  /// 统一的导航处理
  void _navigateTo(BuildContext context, int index) {
    // 避免重复跳转到当前页面 (可选优化)
    if (index == _calculateSelectedIndex(context)) return;
    context.go(appNavigationItems[index].routePath);
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);
    // 安全获取 title，防止索引越界
    final String title = appNavigationItems.length > selectedIndex
        ? appNavigationItems[selectedIndex].label
        : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        // 直接使用 constraints 判断，性能更好且逻辑自洽
        final bool isMobile = constraints.maxWidth < AppConstants.kMobileBreakpoint;

        if (isMobile) {
          // --- 移动端布局 ---
          return Scaffold(
            extendBody: true,
            // Scaffold 默认处理了 bottomNavigationBar 的安全区，
            // 所以这里不需要手动加 Padding，否则会造成溢出或双倍高度。
            bottomNavigationBar: ClipRect(
              child: BackdropFilter(
                // [关键 3] 设置模糊强度 (sigmaX 和 sigmaY)
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    // [关键 4] 去掉选中项的椭圆背景
                    indicatorColor: Colors.transparent,

                    // [关键 5] 设置背景颜色为透明（或者带一点点透明度的白色/黑色，增强可读性）
                    backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(10),

                    // [关键 6] 定义图标颜色状态：选中时用主色，未选中用灰色
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return IconThemeData(
                          color: Theme.of(context).colorScheme.primary.withAlpha(90), // 选中颜色
                          size: 24, // 可选：选中稍微大一点
                        );
                      }
                      return const IconThemeData(
                        color: Colors.grey, // 未选中颜色
                        size: 22,
                      );
                    }),

                    // [关键 7] (可选) 文字颜色也跟随变化
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          color: Theme.of(context).colorScheme.primary.withAlpha(90),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        );
                      }
                      return const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _navigateTo(context, index),
                    // 这里的 height 可以适当调低一点，Material 3 默认较高(80)
                    height: 65,
                    // 强制背景透明，让 NavigationBarTheme 的颜色生效
                    backgroundColor: Colors.transparent,
                    // 移除顶部的分割线 (elevation)
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,

                    destinations: appNavigationItems.map((item) {
                      return NavigationDestination(
                        // 这里直接使用 item.icon 即可，颜色由上面的 iconTheme 控制
                        icon: item.icon,
                        // 也可以单独指定 selectedIcon，如果图标形状不同的话
                        // selectedIcon: Icon(Icons.home_filled),
                        label: item.label,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // 使用 SafeArea 确保内容不被刘海屏遮挡
            body: SafeArea(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        } else {
          // --- 桌面/平板端布局 ---
          return Scaffold(
            body: Row(
              children: [
                // 侧边导航栏
                AdaptiveNavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _navigateTo(context, index),
                  // 如果实现了 extended，可以在这里根据宽度传入
                  // extended: constraints.maxWidth > 1200,
                ),

                //主要内容区域
                Expanded(
                  child: Column(
                    children: [
                      AdaptiveAppBar(
                        title: Text(title),
                        automaticallyImplyLeading: false,
                        height: kToolbarHeight,
                      ),
                      Expanded(
                        child: child ?? const SizedBox.shrink(),
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
}