import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeSiteApi extends SiteApi {
  _FakeSiteApi(this.features);

  final Set<SiteFeature> features;

  @override
  Set<SiteFeature> get supportedFeatures => features;
}

SitePlugin _plugin(String id, Set<SiteFeature> features) {
  return SitePlugin(
    info: SiteInfo(id: id, name: id, version: '1.0.0'),
    createApi: (_) => _FakeSiteApi(features),
  );
}

void main() {
  group('SiteRegistry', () {
    test('keeps independent runtimes for multiple sites', () {
      final registry = SiteRegistry();
      registry.register(_plugin('site.one', {SiteFeature.search}));
      registry.register(_plugin('site.two', {SiteFeature.detail}));

      expect(registry.allInfo.map((info) => info.id), ['site.one', 'site.two']);
      expect(registry.supports('site.one', SiteFeature.search), isTrue);
      expect(registry.supports('site.one', SiteFeature.detail), isFalse);
      expect(registry.supports('site.two', SiteFeature.detail), isTrue);
      expect(
        registry.requireApi('site.one'),
        isNot(same(registry.requireApi('site.two'))),
      );
    });

    test('rejects duplicate IDs and unknown runtime lookups', () {
      final registry = SiteRegistry();
      registry.register(_plugin('site.one', const {}));

      expect(
        () => registry.register(_plugin('site.one', const {})),
        throwsStateError,
      );
      expect(() => registry.requireRuntime('missing'), throwsStateError);
    });
  });
}
