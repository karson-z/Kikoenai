import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/features/user/presentation/pages/user_page.dart';
import '../../features/album/presentation/page/album_detail.dart';
import '../../features/auth/presentation/view_models/provider/auth_provider.dart';
import '../../features/auth/presentation/view_models/state/auth_state.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_overview_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/album/presentation/page/album_page.dart';
import '../../features/category/presentation/page/category_page.dart';
import '../widgets/common/login_dialog_manager.dart';
import '../widgets/layout/app_main_scaffold.dart';
import 'app_auth_config.dart';
import 'app_routes.dart';


/// 用于让 GoRouter 在 auth 状态变化时刷新
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    // 监听 AsyncValue<AuthState> 的变化，触发 notify
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshNotifier(ref);
  return GoRouter(
    navigatorKey: AppConstants.rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      // 读取当前 auth AsyncValue<AuthState>
      final authAsync = ref.read(authNotifierProvider);

      final path = state.uri.path;
      final requiresAuth = routeAuthConfigs[path] ?? false;

      // 如果路由不需要鉴权就放行
      if (!requiresAuth) return null;

      if (authAsync is AsyncData<AuthState>) {
        final authState = authAsync.value;

        if (!authState.isLoggedIn){
          LoginDialogManager().showLoginDialog();
          return null;
        }

        // 已登录 — 放行 (return null)
        return null;
      }

      // 兜底：放行
      return null;
    },

    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => MaterialPage(
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => MaterialPage(
              child: const SettingsOverviewPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.album,
            pageBuilder: (context, state) => MaterialPage(
              child: const AlbumPage(),
            ),
            routes: [GoRoute(
              path: AppRoutes.detailRe,
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                return MaterialPage(
                  child: AlbumDetailPage(extra:extra),
                );
              },
            ),]
          ),
          GoRoute(
            path: AppRoutes.user,
            pageBuilder: (context, state) => MaterialPage(
              child: const UserPage(),
            ),
          ),
          GoRoute(path: AppRoutes.test,
            pageBuilder: (context, state) => MaterialPage(
              child: const CategoryPage(),
            )),
        ],
      ),
      GoRoute(
        path: AppRoutes.settingsTheme,
        pageBuilder: (context, state) => MaterialPage(
          child: const SettingsPage(),
        ),
      ),
    ],
  );
});

