import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/features/about/page/about_page.dart';
import 'package:kikoenai/features/auth/presentation/page/auth_page.dart';
import 'package:kikoenai/features/settings/presentation/pages/account_page.dart';
import 'package:kikoenai/features/settings/presentation/pages/setting_cache_page.dart';
import 'package:kikoenai/features/user/presentation/pages/user_page.dart';
import '../../features/album/presentation/page/album_detail.dart';
import '../../features/settings/presentation/pages/comment_setting_page.dart';
import '../../features/settings/presentation/pages/permission_page.dart';
import '../../features/settings/presentation/pages/settings_overview_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/album/presentation/page/album_page.dart';
import '../../features/category/presentation/page/category_page.dart';
import '../../features/search/presentation/page/search_page.dart';
import '../widgets/common/kikoenai_dialog.dart';
import '../widgets/image_box/image_view.dart';
import '../widgets/layout/app_main_scaffold.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: AppConstants.rootNavigatorKey,
    initialLocation: AppRoutes.home,
    observers: [
      KikoenaiDialog.observer,
    ],
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // 这里传入我们在 MainScaffold 中修改后的 navigationShell
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => MaterialPage(
                  child: const AlbumPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.detail,
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return MaterialPage(
                    child: AlbumDetailPage(extra: extra),
                  );
                },
              ),
            ],
          ),

          // ------------------------------------------------------------------
          // 分支 2: 分类 (Category)
          // ------------------------------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.category,
                pageBuilder: (context, state) => MaterialPage(
                  child: const CategoryPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) => MaterialPage(
                  child: const SettingsOverviewPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.user,
                pageBuilder: (context, state) => MaterialPage(
                  child: const UserPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => MaterialPage(
          child: const AuthPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsTheme,
        pageBuilder: (context, state) => MaterialPage(
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsPermission,
        pageBuilder: (context, state) => MaterialPage(
          child: const PermissionSettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsCache,
        pageBuilder: (context, state) => MaterialPage(
          child: const CacheManagementPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsAccount,
        pageBuilder: (context, state) => MaterialPage(
          child: const AccountPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsComment,
        pageBuilder: (context, state) => MaterialPage(
          child: const GeneralSettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (context, state) => MaterialPage(
          child: const AboutPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.imageView,
        pageBuilder: (context, state) {
          final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            opaque: false, // 必须 false
            barrierColor: Colors.transparent, // 必须透明
            // 缩短路由本身的过渡时间，避免和内部滑动冲突
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            child: ExtendedImagePreviewPage(
              imageUrls: args['urls'] as List<String>,
              initialIndex: args['index'] as int,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SearchPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final tween = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutQuart));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
    ],
  );
});