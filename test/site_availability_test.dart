import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/routes/app_route_surface_policy.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai/features/album/widget/smart_works_sliver_grid.dart';
import 'package:kikoenai/features/playlist/provider/playlist_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeSiteApi extends SiteApi {
  _FakeSiteApi(this.features);

  final Set<SiteFeature> features;

  @override
  Set<SiteFeature> get supportedFeatures => features;
}

SiteRuntime _runtime(
  String siteId,
  Set<SiteFeature> features, {
  List<ServerInfo> servers = const [],
}) {
  return SiteRuntime.fromApi(
    info: SiteInfo(
      id: siteId,
      name: siteId,
      version: '1.0.0',
      servers: servers,
    ),
    api: _FakeSiteApi(features),
  );
}

void main() {
  group('site requirements', () {
    test('compose feature and runtime metadata requirements', () {
      final runtime = _runtime(
        'site.one',
        {SiteFeature.search},
        servers: const [
          ServerInfo(
            id: 'main',
            baseUrl: 'https://example.test',
            label: 'Main',
          ),
        ],
      );
      final context = SiteAvailabilityContext(runtime);

      expect(const Always().isSatisfiedBy(context), isTrue);
      expect(const Supports(SiteFeature.search).isSatisfiedBy(context), isTrue);
      expect(
        const Supports(SiteFeature.detail).isSatisfiedBy(context),
        isFalse,
      );
      expect(
        const AnyOf([
          Supports(SiteFeature.detail),
          Supports(SiteFeature.search),
        ]).isSatisfiedBy(context),
        isTrue,
      );
      expect(
        const AllOf([
          Supports(SiteFeature.search),
          HasServers(),
        ]).isSatisfiedBy(context),
        isTrue,
      );
    });

    test('unknown surface policy fails closed', () {
      const registry = SurfacePolicyRegistry(<AppSurface, SiteRequirement>{});
      final runtime = _runtime('site.one', const {});

      expect(registry.isAvailable(AppSurface.userPage, runtime), isFalse);
    });

    test('default registry defines every application surface', () {
      final runtime = _runtime(
        'site.all',
        SiteFeature.values.toSet(),
        servers: const [
          ServerInfo(
            id: 'main',
            baseUrl: 'https://example.test',
            label: 'Main',
          ),
        ],
      );

      expect(
        defaultSurfacePolicyRegistry.availableFor(runtime),
        AppSurface.values.toSet(),
      );
    });
  });

  test('active site switch updates visible destinations', () async {
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.local-only', const {}))
      ..registerRuntime(_runtime('site.search', {SiteFeature.search}));
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.local-only'),
        siteSelectionPersistenceProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(visibleDestinationsProvider).map((item) => item.label),
      ['本地媒体', '网盘', 'DL库', '我的'],
    );

    await container.read(activeSiteIdProvider.notifier).activate('site.search');

    expect(
      container.read(visibleDestinationsProvider).map((item) => item.label),
      ['首页', '分类', '本地媒体', '网盘', 'DL库', '我的'],
    );
  });

  test('site context can be scoped independently from the active site', () {
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.active', const {}))
      ..registerRuntime(_runtime('site.content', {SiteFeature.tracks}));
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.active'),
        siteContextIdProvider.overrideWithValue('site.content'),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(activeSiteIdProvider), 'site.active');
    expect(container.read(siteContextRuntimeProvider).siteId, 'site.content');
    expect(
      container.read(surfaceAvailableProvider(AppSurface.albumTracksSection)),
      isTrue,
    );
  });

  test(
    'playlist mutations fail safely when the site lacks the feature',
    () async {
      final registry = SiteRegistry()
        ..registerRuntime(_runtime('site.playlists', {SiteFeature.playlists}));
      final container = ProviderContainer(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('site.playlists'),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(playlistWorksMutationProvider.notifier);
      expect(
        await notifier.addWorks(playlistId: 'one', workIds: const [1]),
        isFalse,
      );
      expect(
        await notifier.removeWorks(playlistId: 'one', workIds: const [1]),
        isFalse,
      );
    },
  );

  group('route surface policy', () {
    late SiteRuntime activeRuntime;

    setUp(() {
      activeRuntime = _runtime('site.active', {SiteFeature.search});
    });

    test('uses active site for album detail', () {
      expect(
        appRouteSurfacePolicy.isAvailable(
          path: AppRoutes.detail,
          extra: const {'workId': 1},
          activeRuntime: activeRuntime,
          surfacePolicies: defaultSurfacePolicyRegistry,
        ),
        isFalse,
      );
      expect(
        appRouteSurfacePolicy.isAvailable(
          path: AppRoutes.detail,
          extra: const {'workId': 1},
          activeRuntime: _runtime('site.detail', {
            SiteFeature.detail,
            SiteFeature.tracks,
          }),
          surfacePolicies: defaultSurfacePolicyRegistry,
        ),
        isTrue,
      );
      expect(
        appRouteSurfacePolicy.isAvailable(
          path: AppRoutes.detail,
          extra: const {'workId': 1},
          activeRuntime: _runtime('site.files', {
            SiteFeature.detail,
            SiteFeature.fileSystemSearch,
            SiteFeature.fileSystemBrowse,
          }),
          surfacePolicies: defaultSurfacePolicyRegistry,
        ),
        isFalse,
      );
    });

    test('maps home subroutes to their own capabilities', () {
      expect(
        appRouteSurfacePolicy.isAvailable(
          path: AppRoutes.hotAndRecommend,
          extra: const {'source': WorkDataSource.newest},
          activeRuntime: activeRuntime,
          surfacePolicies: defaultSurfacePolicyRegistry,
        ),
        isTrue,
      );
      expect(
        appRouteSurfacePolicy.isAvailable(
          path: AppRoutes.hotAndRecommend,
          extra: const {'source': WorkDataSource.recommended},
          activeRuntime: activeRuntime,
          surfacePolicies: defaultSurfacePolicyRegistry,
        ),
        isFalse,
      );
    });
  });
}
