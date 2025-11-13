import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:name_app/core/constants/app_constants.dart';
import 'package:name_app/core/common/app_transition_page.dart';
import 'package:name_app/core/routes/app_auth_config.dart';
import 'package:name_app/core/widgets/layout/app_main_scaffold.dart';
import 'package:name_app/core/widgets/common/login_dialog_manager.dart';
import 'package:name_app/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:name_app/core/routes/app_routes.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/user/presentation/pages/user_page.dart';
import '../../features/settings/presentation/pages/settings_overview_page.dart';
import '../../features/album/presentation/page/album_page.dart';

/// 应用的主要路由配置
final authViewModel = GetIt.I<AuthViewModel>();

// --- 全局重定向守卫逻辑 ---
String? _redirectGuard(BuildContext context, GoRouterState state) {
  // 1. 根据当前路径查找权限配置
  final String path = state.uri.path;

  // 查找配置表。如果路径不在配置表中，则默认 requiresAuth 为 true (需要守卫)。
  final bool requiresAuth = routeAuthConfigs[path] ?? false;

  // 2. 如果当前路由不需要认证，则直接放行
  if (!requiresAuth) {
    return null;
  }

  // 3. 如果需要认证，则检查登录状态
  if (!authViewModel.isLoggedIn) {
    // 在登录成功后自动导航到目标页。 （注意：这里的导航是异步的，不会阻塞当前路由,直接打开全局弹窗，然后在登录成功后导航到目标页）
    // 取消登录则跳转回首页。
    LoginDialogManager().showLoginDialog();

    // 直接滚去首页好吧
    return AppRoutes.home;
  }

  // 4. 已登录且需要认证，放行
  return null;
}

// -----------------------------
final GoRouter router = GoRouter(
  refreshListenable: authViewModel,
  navigatorKey: AppConstants.rootNavigatorKey,
  // 顶级守卫
  redirect: _redirectGuard,
  routes: <RouteBase>[
    // Shell路由 (共享 MainScaffold)
    ShellRoute(
      builder: (context, state, child) {
        // 全局布局入口，承接主内容区
        return MainScaffold(child: child);
      },
      routes: <RouteBase>[
        // 1. 首页: 权限由配置表控制
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => AppTransitionPage(
            state: state,
            child: const HomePage(),
            type: PageTransitionType.fade,
          ),
        ),

        // 2. 用户页: 权限由配置表控制 (默认需要认证)
        GoRoute(
          path: AppRoutes.user,
          pageBuilder: (context, state) => AppTransitionPage(
            state: state,
            child: const UserPage(),
            type: PageTransitionType.fade,
          ),
        ),

        // 3. 设置概览页: 权限由配置表控制
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => AppTransitionPage(
            state: state,
            child: const SettingsOverviewPage(),
            type: PageTransitionType.fade,
          ),
        ),

        // 4. 专辑页: 权限由配置表控制
        GoRoute(
          path: AppRoutes.album,
          pageBuilder: (context, state) => AppTransitionPage(
            state: state,
            child: const AlbumPage(),
            type: PageTransitionType.fade,
          ),
        ),
      ],
    ),

    // 5. 独立路由 (主题设置页): 权限由配置表控制
    GoRoute(
      path: AppRoutes.settingsTheme,
      pageBuilder: (context, state) => AppTransitionPage(
        state: state,
        child: const SettingsPage(),
        type: PageTransitionType.fade,
      ),
    ),
  ],
);
