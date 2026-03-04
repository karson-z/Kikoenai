import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/core/routes/app_routes.dart'; // 确保这个路径正确

/// 一个自适应的、响应式的脚手架，
/// 在小屏幕上显示 BottomNavigationBar，在大屏幕上显示 NavigationRail。
class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.routePath,
  });

  final String label;
  final Widget icon; // icon 永远是同一个
  final String routePath;
}

/// 应用程序的主导航项列表。
/// icon 统一使用 outline 版本，选中时通过颜色变化区分
const List<NavigationItem> appNavigationItems = [
  NavigationItem(
    label: '首页',
    icon: Icon(Icons.home_outlined),
    routePath: AppRoutes.home, // e.g., "/"
  ),
  NavigationItem(
    label: '分类',
    icon: Icon(Icons.auto_awesome_outlined),
    routePath: AppRoutes.category, // e.g., "/album"
  ),
  NavigationItem(
    label: '设置',
    icon: Icon(Icons.settings_outlined),
    routePath: AppRoutes.settings, // e.g., "/settings"
  ),
  NavigationItem(
    label: '我的',
    // 完美符合：带外圆的用户图标
    icon: Icon(Icons.account_circle_outlined),
    routePath: AppRoutes.user,
  ),
  NavigationItem(label: '测试', icon:Icon(Icons.tab_sharp), routePath: AppRoutes.test)
];
