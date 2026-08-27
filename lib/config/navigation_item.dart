import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/routes/app_routes.dart'; // 确保这个路径正确

import '../core/service/site/site_availability.dart';

/// 一个自适应的、响应式的脚手架，
/// 在小屏幕上显示 BottomNavigationBar，在大屏幕上显示 NavigationRail。
class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.routePath,
    required this.branchIndex,
    required this.surface,
  });

  final String label;
  final Widget icon; // icon 永远是同一个
  final String routePath;
  final int branchIndex;
  final AppSurface surface;
}

/// 应用程序的主导航项列表。
/// icon 统一使用 outline 版本，选中时通过颜色变化区分
const List<NavigationItem> appNavigationItems = [
  NavigationItem(
    label: '首页',
    icon: Icon(Icons.home_outlined),
    routePath: AppRoutes.home, // e.g., "/"
    branchIndex: 0,
    surface: AppSurface.homePage,
  ),
  NavigationItem(
    label: '分类',
    icon: Icon(Icons.auto_awesome_outlined),
    routePath: AppRoutes.category, // e.g., "/album"
    branchIndex: 1,
    surface: AppSurface.categoryPage,
  ),
  NavigationItem(
    label: '本地媒体',
    icon: Icon(Icons.perm_media_outlined),
    routePath: AppRoutes.localMedia,
    branchIndex: 2,
    surface: AppSurface.localMediaPage,
  ),
  NavigationItem(
    label: '网盘',
    icon: Icon(Icons.cloud_outlined),
    routePath: AppRoutes.cloudDrive,
    branchIndex: 3,
    surface: AppSurface.cloudDrivePage,
  ),
  NavigationItem(
    label: 'DL库',
    icon: Icon(Icons.library_music_outlined),
    routePath: AppRoutes.parsedWorks,
    branchIndex: 4,
    surface: AppSurface.parsedWorksPage,
  ),
  NavigationItem(
    label: '我的',
    icon: Icon(Icons.account_circle_outlined),
    routePath: AppRoutes.user,
    branchIndex: 5,
    surface: AppSurface.userPage,
  ),
  // NavigationItem(label: '测试', icon:Icon(Icons.tab_sharp), routePath: AppRoutes.test)
];

final visibleDestinationsProvider = Provider<List<NavigationItem>>((ref) {
  final availableSurfaces = ref.watch(availableSurfacesProvider);
  return List.unmodifiable(
    appNavigationItems.where(
      (item) => availableSurfaces.contains(item.surface),
    ),
  );
});
