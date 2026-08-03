import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/routes/app_router.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/service/site/site_unavailable_controller.dart';
import 'package:kikoenai/features/site/page/site_unavailable_page.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _UnavailableSiteApi extends SiteApi {
  @override
  Set<SiteFeature> get supportedFeatures => const {
    SiteFeature.healthCheck,
    SiteFeature.serverSwitch,
  };
}

const _server = ServerInfo(
  id: 'primary',
  baseUrl: 'https://primary.example/api',
  label: 'Primary',
  isDefault: true,
);

void main() {
  test(
    'controller preserves the original return route for repeated reports',
    () {
      final controller = SiteUnavailableController();
      addTearDown(controller.dispose);

      controller.report(siteId: 'site.test', serverIds: const ['primary']);
      controller.captureReturnLocation('/detail', extra: const {'workId': 42});
      controller.report(
        siteId: 'site.test',
        serverIds: const ['primary', 'backup'],
      );

      expect(controller.incident?.returnLocation, '/detail');
      expect(controller.incident?.returnExtra, const {'workId': 42});
      expect(controller.incident?.serverIds, ['primary', 'backup']);
    },
  );

  testWidgets('renders dedicated unavailable actions on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = SiteUnavailableController()
      ..report(siteId: 'site.test', serverIds: const ['primary']);
    addTearDown(controller.dispose);
    final registry = SiteRegistry()
      ..registerRuntime(
        SiteRuntime.fromApi(
          info: const SiteInfo(
            id: 'site.test',
            name: '测试站点',
            version: '1.0.0',
            servers: [_server],
          ),
          api: _UnavailableSiteApi(),
        ),
      )
      ..registerRuntime(
        SiteRuntime.fromApi(
          info: const SiteInfo(
            id: 'site.other',
            name: '备用站点',
            version: '1.0.0',
          ),
          api: _UnavailableSiteApi(),
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('site.test'),
          siteUnavailableControllerProvider.overrideWithValue(controller),
        ],
        child: const MaterialApp(home: SiteUnavailablePage()),
      ),
    );

    expect(find.text('测试站点 暂时无法连接'), findsOneWidget);
    expect(find.text('已检查 1 个服务器，均未响应'), findsOneWidget);
    expect(find.text('重新检测'), findsOneWidget);
    expect(find.text('选择服务器'), findsOneWidget);
    expect(find.text('切换站点'), findsOneWidget);
    expect(find.text('使用本地媒体'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('router redirects an unavailable incident to the error page', (
    tester,
  ) async {
    final controller = SiteUnavailableController()
      ..report(siteId: 'site.test', serverIds: const ['primary']);
    addTearDown(controller.dispose);
    final registry = SiteRegistry()
      ..registerRuntime(
        SiteRuntime.fromApi(
          info: const SiteInfo(
            id: 'site.test',
            name: '测试站点',
            version: '1.0.0',
            servers: [_server],
          ),
          api: _UnavailableSiteApi(),
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('site.test'),
          siteUnavailableControllerProvider.overrideWithValue(controller),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp.router(
              routerConfig: ref.watch(goRouterProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SiteUnavailablePage), findsOneWidget);
    expect(find.text('测试站点 暂时无法连接'), findsOneWidget);
    expect(controller.incident?.returnLocation, '/');
  });
}
