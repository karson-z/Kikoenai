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
    expect(registry.activeId, 'site.two');
    expect(persisted, ['site.two']);
  });

  test('active site switch keeps the registry in sync', () async {
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.one', const {}))
      ..registerRuntime(_runtime('site.two', const {}));

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
    expect(registry.activeId, 'site.two');
  });

  test('AList runtime cannot be activated as the content site', () async {
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.one', {SiteFeature.search}))
      ..registerRuntime(
        _runtime(AsmrGaySiteApi.info.id, {SiteFeature.fileSystemBrowse}),
      );
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.one'),
        siteSelectionPersistenceProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(activeSiteIdProvider.notifier)
          .activate(AsmrGaySiteApi.info.id),
      throwsArgumentError,
    );
    expect(container.read(activeSiteIdProvider), 'site.one');
  });

  test('an initial AList selection falls back to a content site', () {
    final registry = SiteRegistry()
      ..registerRuntime(
        _runtime(AsmrGaySiteApi.info.id, {SiteFeature.fileSystemBrowse}),
      )
      ..registerRuntime(_runtime('site.one', {SiteFeature.search}));
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue(AsmrGaySiteApi.info.id),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(activeSiteIdProvider), 'site.one');
    expect(registry.activeId, 'site.one');
  });
}
