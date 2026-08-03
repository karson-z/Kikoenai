import 'server_health.dart';
import 'server_info.dart';
import 'site_api.dart';
import 'site_feature.dart';
import 'site_info.dart';
import 'site_plugin.dart';
import 'site_runtime.dart';

/// Registry of site plugins, their isolated runtimes, and server state.
class SiteRegistry {
  final Map<String, SiteRuntime> _runtimes = {};
  String? _activeId;

  /// 当前激活站点 ID。
  String? get activeId => _activeId;

  set activeId(String? siteId) {
    if (siteId != null && !contains(siteId)) {
      throw StateError('站点 $siteId 未注册');
    }
    _activeId = siteId;
  }

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
    _activeId ??= siteId;
  }

  SiteRuntime? runtimeOf(String siteId) => _runtimes[siteId];

  SiteApi? apiOf(String siteId) => runtimeOf(siteId)?.api;

  SiteInfo? infoOf(String siteId) => runtimeOf(siteId)?.info;

  List<SiteRuntime> get allRuntimes => List.unmodifiable(_runtimes.values);

  List<SiteInfo> get allInfo =>
      List.unmodifiable(_runtimes.values.map((runtime) => runtime.info));

  List<SiteApi> get allApis =>
      List.unmodifiable(_runtimes.values.map((runtime) => runtime.api));

  SiteRuntime? get activeRuntime =>
      _activeId == null ? null : runtimeOf(_activeId!);

  SiteApi? get activeApi => activeRuntime?.api;

  SiteInfo? get activeInfo => activeRuntime?.info;

  bool contains(String siteId) => _runtimes.containsKey(siteId);

  bool supports(String siteId, SiteFeature feature) =>
      apiOf(siteId)?.supports(feature) ?? false;

  List<SiteApi> sitesWithFeature(SiteFeature feature) =>
      allApis.where((api) => api.supports(feature)).toList(growable: false);

  SiteRuntime requireRuntime(String siteId) {
    final runtime = runtimeOf(siteId);
    if (runtime == null) throw StateError('站点 $siteId 未注册');
    return runtime;
  }

  SiteApi requireApi(String siteId) => requireRuntime(siteId).api;

  List<ServerInfo> serversOf(String siteId) =>
      infoOf(siteId)?.servers ?? const [];

  ServerInfo? currentServerOf(String siteId) {
    final api = apiOf(siteId);
    if (api != null && api.supports(SiteFeature.serverSwitch)) {
      return api.currentServer;
    }
    return infoOf(siteId)?.defaultServer;
  }

  Future<void> switchServer(String siteId, String serverId) async {
    final api = apiOf(siteId);
    if (api == null || !api.supports(SiteFeature.serverSwitch)) {
      throw UnsupportedError('站点 $siteId 不支持服务器切换');
    }
    final server = _requireServer(siteId, serverId);
    await api.switchServer(server);
  }

  Future<ServerHealth> checkServerHealth(String siteId, String serverId) async {
    final api = apiOf(siteId);
    if (api == null || !api.supports(SiteFeature.healthCheck)) {
      throw UnsupportedError('站点 $siteId 不支持健康检查');
    }
    return api.checkHealth(_requireServer(siteId, serverId));
  }

  Future<List<ServerHealth>> checkAllServerHealth(String siteId) async {
    final api = apiOf(siteId);
    if (api == null || !api.supports(SiteFeature.healthCheck)) {
      throw UnsupportedError('站点 $siteId 不支持健康检查');
    }
    final servers = serversOf(siteId);
    if (servers.isEmpty) return const [];
    return api.checkAllHealth(servers);
  }

  /// 选择默认健康服务器；默认服务器不可用时选择列表中第一个健康服务器。
  /// [excludedServerIds] 用于故障恢复时跳过刚刚失败的服务器。
  Future<ServerInfo?> selectHealthyServer(
    String siteId, {
    Set<String> excludedServerIds = const {},
  }) async {
    final api = apiOf(siteId);
    if (api == null ||
        !api.supports(SiteFeature.healthCheck) ||
        !api.supports(SiteFeature.serverSwitch)) {
      return null;
    }

    final servers = serversOf(
      siteId,
    ).where((server) => !excludedServerIds.contains(server.id)).toList();
    if (servers.isEmpty) return null;

    final healths = await api.checkAllHealth(servers);
    final healthByServerId = {
      for (final health in healths) health.serverId: health,
    };
    final defaultServer = infoOf(siteId)?.defaultServer;
    if (defaultServer != null &&
        healthByServerId[defaultServer.id]?.isHealthy == true) {
      await api.switchServer(defaultServer);
      return defaultServer;
    }

    for (final server in servers) {
      if (healthByServerId[server.id]?.isHealthy == true) {
        await api.switchServer(server);
        return server;
      }
    }
    return null;
  }

  /// 为所有支持服务器切换和健康检查的站点选择健康服务器。
  Future<Map<String, ServerInfo?>> bootstrapHealthyServers() async {
    final result = <String, ServerInfo?>{};
    for (final info in allInfo) {
      if (info.servers.isEmpty ||
          !supports(info.id, SiteFeature.healthCheck) ||
          !supports(info.id, SiteFeature.serverSwitch)) {
        continue;
      }
      result[info.id] = await selectHealthyServer(info.id);
    }
    return result;
  }

  ServerInfo _requireServer(String siteId, String serverId) {
    return serversOf(siteId).firstWhere(
      (server) => server.id == serverId,
      orElse: () => throw ArgumentError('站点 $siteId 不存在服务器 $serverId'),
    );
  }

  void unregister(String siteId, {bool dispose = true}) {
    final runtime = _runtimes.remove(siteId);
    if (dispose) runtime?.dispose();
    if (_activeId == siteId) {
      _activeId = _runtimes.isEmpty ? null : _runtimes.keys.first;
    }
  }

  void clear({bool dispose = true}) {
    if (dispose) {
      for (final runtime in _runtimes.values) {
        runtime.dispose();
      }
    }
    _runtimes.clear();
    _activeId = null;
  }
}
