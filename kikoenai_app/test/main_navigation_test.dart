import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/routes/app_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';

void main() {
  test('main navigation items stay aligned with shell branches', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    final shellRoute = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    expect(appNavigationItems.map((item) => item.label), [
      '首页',
      '分类',
      '本地媒体',
      'DL库',
      '我的',
    ]);
    expect(appNavigationItems.map((item) => item.routePath), [
      AppRoutes.home,
      AppRoutes.category,
      AppRoutes.localMedia,
      AppRoutes.parsedWorks,
      AppRoutes.user,
    ]);
    expect(shellRoute.branches, hasLength(appNavigationItems.length));
    expect(
      shellRoute.branches.map(
        (branch) => (branch.routes.first as GoRoute).path,
      ),
      appNavigationItems.map((item) => item.routePath),
    );
    expect(AppRoutes.mainPages, contains(AppRoutes.parsedWorks));
  });
}
