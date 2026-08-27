import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/routes/app_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeSiteApi extends SiteApi {
  @override
  Set<SiteFeature> get supportedFeatures => SiteFeature.values.toSet();
}

void main() {
  test('main navigation items stay aligned with shell branches', () {
    final registry = SiteRegistry()
      ..registerRuntime(
        SiteRuntime.fromApi(
          info: const SiteInfo(id: 'site.test', name: 'Test', version: '1.0.0'),
          api: _FakeSiteApi(),
        ),
      );
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.test'),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    final shellRoute = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    expect(appNavigationItems.map((item) => item.label), [
      '首页',
      '分类',
      '本地媒体',
      '网盘',
      'DL库',
      '我的',
    ]);
    expect(appNavigationItems.map((item) => item.routePath), [
      AppRoutes.home,
      AppRoutes.category,
      AppRoutes.localMedia,
      AppRoutes.cloudDrive,
      AppRoutes.parsedWorks,
      AppRoutes.user,
    ]);
    expect(shellRoute.branches, hasLength(appNavigationItems.length));
    expect(appNavigationItems.map((item) => item.branchIndex), [
      0,
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(
      shellRoute.branches.map(
        (branch) => (branch.routes.first as GoRoute).path,
      ),
      appNavigationItems.map((item) => item.routePath),
    );
    expect(AppRoutes.mainPages, contains(AppRoutes.parsedWorks));
  });
}
