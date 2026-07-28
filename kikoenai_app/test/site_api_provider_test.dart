import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeSiteApi extends SiteApi {
  _FakeSiteApi(this.features);

  final Set<SiteFeature> features;

  @override
  Set<SiteFeature> get supportedFeatures => features;
}

SiteRuntime _runtime(String siteId, Set<SiteFeature> features) {
  return SiteRuntime.fromApi(
    info: SiteInfo(id: siteId, name: siteId, version: '1.0.0'),
    api: _FakeSiteApi(features),
  );
}

void main() {
  test('active site switch updates API, info, and feature providers', () async {
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.one', {SiteFeature.search}))
      ..registerRuntime(_runtime('site.two', {SiteFeature.detail}));
    final persisted = <String>[];
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.one'),
        siteSelectionPersistenceProvider.overrideWithValue((siteId) async {
          persisted.add(siteId);
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(activeSiteInfoProvider).id, 'site.one');
    expect(container.read(siteSupportsProvider(SiteFeature.search)), isTrue);

    await container.read(activeSiteIdProvider.notifier).activate('site.two');

    expect(container.read(activeSiteInfoProvider).id, 'site.two');
    expect(container.read(siteSupportsProvider(SiteFeature.search)), isFalse);
    expect(container.read(siteSupportsProvider(SiteFeature.detail)), isTrue);
    expect(persisted, ['site.two']);
  });

  test('switch ignores sites absent from the compatibility manager', () async {
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.one', const {}))
      ..registerRuntime(_runtime('site.two', const {}));
    final legacyManager = SiteManager.instance;
    final previousActiveId = legacyManager.activeId;
    legacyManager.activeId = 'legacy.site';
    addTearDown(() => legacyManager.activeId = previousActiveId);

    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.one'),
        siteSelectionPersistenceProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);

    await container.read(activeSiteIdProvider.notifier).activate('site.two');

    expect(container.read(activeSiteIdProvider), 'site.two');
    expect(legacyManager.activeId, 'legacy.site');
  });
}
