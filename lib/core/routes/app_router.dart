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
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
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
                child: AlbumDetailPage(extra:extra),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => MaterialPage(
              child: const SettingsOverviewPage(),
            ),
          ),
          GoRoute(path: AppRoutes.category,
              pageBuilder: (context, state) => MaterialPage(
                child: const CategoryPage(),
              )
          ),
          GoRoute(
            path: AppRoutes.user,
            pageBuilder: (context, state) => MaterialPage(
              child: const UserPage(),
            ),
          ),
          // GoRoute(
          //   path: AppRoutes.test,
          //   pageBuilder: (context, state) => MaterialPage(
          //     child: const SearchPage(),
          //   ),
          // ),
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

