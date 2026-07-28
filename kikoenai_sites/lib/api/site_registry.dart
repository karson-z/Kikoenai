import 'site_api.dart';
import 'site_feature.dart';
import 'site_info.dart';
import 'site_plugin.dart';
import 'site_runtime.dart';

/// Injectable registry of site plugins and their isolated runtime instances.
class SiteRegistry {
  final Map<String, SiteRuntime> _runtimes = {};

  SiteRuntime register(
    SitePlugin plugin, {
    SiteRuntimeContext context = const SiteRuntimeContext(),
  }) {
    final runtime = SiteRuntime.create(plugin, context: context);
    registerRuntime(runtime);
    return runtime;
  }

  void registerRuntime(SiteRuntime runtime) {
    final siteId = runtime.siteId;
    if (_runtimes.containsKey(siteId)) {
      throw StateError('站点 $siteId 已注册');
    }
    _runtimes[siteId] = runtime;
  }

  SiteRuntime? runtimeOf(String siteId) => _runtimes[siteId];

  SiteApi? apiOf(String siteId) => runtimeOf(siteId)?.api;

  SiteInfo? infoOf(String siteId) => runtimeOf(siteId)?.info;

  List<SiteRuntime> get allRuntimes => List.unmodifiable(_runtimes.values);

  List<SiteInfo> get allInfo =>
      List.unmodifiable(_runtimes.values.map((runtime) => runtime.info));

  bool contains(String siteId) => _runtimes.containsKey(siteId);

  bool supports(String siteId, SiteFeature feature) =>
      apiOf(siteId)?.supports(feature) ?? false;

  SiteRuntime requireRuntime(String siteId) {
    final runtime = runtimeOf(siteId);
    if (runtime == null) throw StateError('站点 $siteId 未注册');
    return runtime;
  }

  SiteApi requireApi(String siteId) => requireRuntime(siteId).api;

  void unregister(String siteId, {bool dispose = true}) {
    final runtime = _runtimes.remove(siteId);
    if (dispose) runtime?.dispose();
  }

  void clear({bool dispose = true}) {
    if (dispose) {
      for (final runtime in _runtimes.values) {
        runtime.dispose();
      }
    }
    _runtimes.clear();
  }
}
