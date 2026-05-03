import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/features/about/page/about_page.dart';
import 'package:kikoenai/features/auth/presentation/page/auth_page.dart';
import 'package:kikoenai/features/local_media/presentation/page/local_media_page.dart';
import 'package:kikoenai/features/log/logger_view.dart';
import 'package:kikoenai/features/settings/presentation/pages/setting_cache_page.dart';
import 'package:kikoenai/features/test/test.dart';
import 'package:kikoenai/features/user/presentation/pages/user_page.dart';
import '../../features/album/presentation/page/album_detail.dart';
import '../../features/album/presentation/page/category_works_page.dart';
import '../../features/album/presentation/widget/smart_works_sliver_grid.dart';
import '../../features/settings/presentation/pages/setting_page.dart';
import '../../features/settings/presentation/pages/permission_page.dart';
import '../../features/album/presentation/page/album_page.dart';
import '../../features/category/presentation/page/category_page.dart';
import '../../features/search/presentation/page/search_page.dart';
import '../../features/settings/presentation/pages/theme_setting_page.dart';
import '../widgets/animation/slide_right_transition.dart';
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
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => const MaterialPage(
                  child: AlbumPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.hotAndRecommend,
                pageBuilder: (context, state) {
                  // 从 extra 中解析参数
                  final args = state.extra as Map<String, dynamic>?;
                  final title = args?['title'] as String? ?? '更多作品';
                  final source = args?['source'] as WorkDataSource? ?? WorkDataSource.newest;
                  return SlideRightTransitionPage(
                    key: state.pageKey,
                    child: CategoryWorksPage(title: title, source: source),
                  );
                },
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.category,
                pageBuilder: (context, state) => const MaterialPage(
                  child: CategoryPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.localMedia,
                pageBuilder: (context, state) => const MaterialPage(
                  child: ScannerPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.user,
                pageBuilder: (context, state) => const MaterialPage(
                  child: UserPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.test,
                pageBuilder: (context, state) => const MaterialPage(
                  child: GlobalFilterTagsPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const MaterialPage(
          child: AuthPage(),
        ),
      ),
      GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => SlideRightTransitionPage(
            key: state.pageKey,
            child: const SettingsPage(),
          ),
          routes: [
            // 1. 关于页面
            GoRoute(
              path: AppRoutes.toRelative(AppRoutes.about),
              pageBuilder: (context, state) => SlideRightTransitionPage(
                key: state.pageKey, // 传入 pageKey 保证动画期间的状态一致性
                child: const AboutPage(),
              ),
            ),

            // 2. 权限设置
            GoRoute(
              path: AppRoutes.toRelative(AppRoutes.settingsPermission),
              pageBuilder: (context, state) => SlideRightTransitionPage(
                key: state.pageKey,
                child: const PermissionSettingsPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.toRelative(AppRoutes.settingsLog),
              pageBuilder: (context, state) => SlideRightTransitionPage(
                key: state.pageKey,
                child: const LogViewerPage(),
              ),
            ),

            // 3. 主题设置
            GoRoute(
              path: AppRoutes.toRelative(AppRoutes.settingsTheme),
              pageBuilder: (context, state) => SlideRightTransitionPage(
                key: state.pageKey,
                child: const ThemeSettingPage(),
              ),
            ),

            // 4. 缓存设置
            GoRoute(
              path: AppRoutes.toRelative(AppRoutes.settingsCache),
              pageBuilder: (context, state) => SlideRightTransitionPage(
                key: state.pageKey,
                child: const CacheManagementPage(),
              ),
            ),
          ]
      ),
      GoRoute(
        path: AppRoutes.imageView,
        pageBuilder: (context, state) {
          final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            opaque: false,
            barrierColor: Colors.transparent,
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
        pageBuilder: (context, state) => SlideRightTransitionPage(
          key: state.pageKey, // 传入 pageKey 保持状态
          child: const SearchPage(),
        ),
      ),
    ],
  );
});