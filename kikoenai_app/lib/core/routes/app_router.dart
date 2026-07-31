import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/features/about/page/about_page.dart';
import 'package:kikoenai/features/auth/page/auth_page.dart';
import 'package:kikoenai/features/local_media/page/local_media_page.dart';
import 'package:kikoenai/features/local_media/page/parsed_works_page.dart';
import 'package:kikoenai/features/log/page/logger_view.dart';
import 'package:kikoenai/features/settings/page/setting_cache_page.dart';
import 'package:kikoenai/features/settings/page/global_filter_page.dart';
import 'package:kikoenai/features/user/page/user_page.dart';
import 'package:kikoenai/config/navigation_item.dart';
import '../../features/album/page/album_detail.dart';
import '../../features/album/page/category_works_page.dart';
import '../../features/album/widget/smart_works_sliver_grid.dart';
import '../../features/settings/page/setting_page.dart';
import '../../features/settings/page/permission_page.dart';
import '../../features/album/page/album_page.dart';
import '../../features/category/page/category_page.dart';
import '../../features/search/page/search_page.dart';
import '../../features/settings/page/theme_setting_page.dart';
import '../widgets/animation/slide_right_transition.dart';
import '../widgets/common/kikoenai_dialog.dart';
import '../service/site/site_api_provider.dart';
import '../service/site/site_availability.dart';
import '../widgets/image_box/image_view.dart';
import '../widgets/layout/app_main_scaffold.dart';
import 'app_routes.dart';
import 'app_route_surface_policy.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.read(activeSiteIdProvider);
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(activeSiteIdProvider, (_, __) => refreshNotifier.refresh());

  final router = GoRouter(
    navigatorKey: AppConstants.rootNavigatorKey,
    initialLocation: AppRoutes.home,
    observers: [KikoenaiDialog.observer],
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isAvailable = appRouteSurfacePolicy.isAvailable(
        path: state.uri.path,
        extra: state.extra,
        activeRuntime: ref.read(activeSiteProvider),
        siteRegistry: ref.read(siteRegistryProvider),
        surfacePolicies: ref.read(surfacePolicyRegistryProvider),
      );
      if (isAvailable) return null;

      final destinations = ref.read(visibleDestinationsProvider);
      return destinations.isEmpty
          ? AppRoutes.localMedia
          : destinations.first.routePath;
    },
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
                pageBuilder: (context, state) =>
                    const MaterialPage(child: AlbumPage()),
              ),
              GoRoute(
                path: AppRoutes.hotAndRecommend,
                pageBuilder: (context, state) {
                  // 从 extra 中解析参数
                  final args = state.extra as Map<String, dynamic>?;
                  final title = args?['title'] as String? ?? '更多作品';
                  final source =
                      args?['source'] as WorkDataSource? ??
                      WorkDataSource.newest;
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
                  return MaterialPage(child: AlbumDetailPage(extra: extra));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.category,
                pageBuilder: (context, state) =>
                    const MaterialPage(child: CategoryPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.localMedia,
                pageBuilder: (context, state) =>
                    const MaterialPage(child: ScannerPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parsedWorks,
                pageBuilder: (context, state) =>
                    const MaterialPage(child: ParsedWorksPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.user,
                pageBuilder: (context, state) =>
                    const MaterialPage(child: UserPage()),
              ),
            ],
          ),
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: AppRoutes.test,
          //       pageBuilder: (context, state) => const MaterialPage(
          //         child: GlobalFilterTagsPage(),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const MaterialPage(child: AuthPage()),
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
          GoRoute(
            path: AppRoutes.toRelative(AppRoutes.settingsGlobalFilter),
            pageBuilder: (context, state) => SlideRightTransitionPage(
              key: state.pageKey,
              child: const GlobalFilterTagsPage(),
            ),
          ),
        ],
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
