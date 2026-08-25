import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../cache/cache_service.dart';
import 'site_api_setup.dart';

final siteRegistryChangesProvider = StreamProvider<int>((ref) {
  return siteRegistry.changes;
});

final siteRegistryProvider = Provider<SiteRegistry>((ref) => siteRegistry);

final initialActiveSiteIdProvider = Provider<String>((ref) {
  return initialActiveSiteId;
});

final siteSelectionPersistenceProvider =
    Provider<Future<void> Function(String)>((ref) {
      return CacheService.instance.saveActiveSiteId;
    });

class ActiveSiteIdNotifier extends Notifier<String> {
  @override
  String build() {
    ref.watch(siteRegistryChangesProvider);
    final registry = ref.watch(siteRegistryProvider);
    final currentId = registry.activeId;
    if (currentId != null && registry.contains(currentId)) {
      return currentId;
    }
    final initialId = ref.watch(initialActiveSiteIdProvider);
    if (registry.contains(initialId)) {
      registry.activeId = initialId;
      return initialId;
    }
    if (registry.allInfo.isEmpty) {
      throw StateError('没有已注册的站点');
    }
    final fallbackId = registry.allInfo.first.id;
    registry.activeId = fallbackId;
    return fallbackId;
  }

  Future<void> activate(String siteId) async {
    final registry = ref.read(siteRegistryProvider);
    registry.requireRuntime(siteId);
    if (state == siteId) return;

    await ref.read(siteSelectionPersistenceProvider)(siteId);
    registry.activeId = siteId;
    state = siteId;
  }
}

final activeSiteIdProvider = NotifierProvider<ActiveSiteIdNotifier, String>(
  ActiveSiteIdNotifier.new,
);

final siteRuntimeByIdProvider = Provider.family<SiteRuntime, String>((
  ref,
  siteId,
) {
  ref.watch(siteRegistryChangesProvider);
  return ref.watch(siteRegistryProvider).requireRuntime(siteId);
});

final siteApiByIdProvider = Provider.family<SiteApi, String>((ref, siteId) {
  return ref.watch(siteRuntimeByIdProvider(siteId)).api;
});

final siteInfoByIdProvider = Provider.family<SiteInfo, String>((ref, siteId) {
  return ref.watch(siteRuntimeByIdProvider(siteId)).info;
});

final activeSiteProvider = Provider<SiteRuntime>((ref) {
  final siteId = ref.watch(activeSiteIdProvider);
  return ref.watch(siteRuntimeByIdProvider(siteId));
});

final activeSiteInfoProvider = Provider<SiteInfo>((ref) {
  return ref.watch(activeSiteProvider).info;
});

final activeSiteApiProvider = Provider<SiteApi>((ref) {
  return ref.watch(activeSiteProvider).api;
});

final siteSupportsProvider = Provider.family<bool, SiteFeature>((ref, feature) {
  return ref.watch(activeSiteApiProvider).supports(feature);
});

final siteHttpClientByIdProvider = Provider.family<SitesHttpClient, String>((
  ref,
  siteId,
) {
  final runtime = ref.watch(siteRuntimeByIdProvider(siteId));
  final client = runtime.httpClient;
  if (client == null) {
    throw UnsupportedError('站点 $siteId 没有可直接访问的 HTTP 客户端');
  }
  return client;
});

/// Compatibility aliases while remaining callers migrate to active-site names.
final siteApiProvider = Provider<SiteApi>((ref) {
  return ref.watch(activeSiteApiProvider);
});

final sitesHttpClientProvider = Provider<SitesHttpClient>((ref) {
  final siteId = ref.watch(activeSiteIdProvider);
  return ref.watch(siteHttpClientByIdProvider(siteId));
});
