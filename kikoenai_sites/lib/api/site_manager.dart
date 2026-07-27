import 'server_health.dart';
import 'server_info.dart';
import 'site_api.dart';
import 'site_feature.dart';
import 'site_info.dart';

/// 站点条目：关联站点元信息与站点实现对象
class _SiteEntry {
  final SiteInfo info;
  final SiteApi api;

  const _SiteEntry({required this.info, required this.api});
}

/// 站点管理器：注册、查询、按功能检索站点，以及服务器切换与健康检查。
///
/// 所有站点统一实现 [SiteApi]，通过 [SiteApi.supportedFeatures] 声明支持的功能点。
/// 本管理器不再维护 capability 接口筛选，而是通过 [SiteFeature] 进行细粒度查询。
///
/// ### 服务器管理
///
/// 站点可在 [SiteInfo.servers] 中声明多个服务器（镜像 / CDN 节点），
/// 在 [SiteApi.supportedFeatures] 中声明 [SiteFeature.serverSwitch] /
/// [SiteFeature.healthCheck] 后，即可获得运行时切换 / 健康检查的能力。
///
/// ```dart
/// // 注册
/// SiteManager.instance.register(
///   info: AsmrOneSiteApi.info,
///   api: AsmrOneSiteApi(),
/// );
///
/// // 启动时自动选择健康服务器
/// await SiteManager.instance.bootstrapHealthyServers();
///
/// // 运行时手动切换
/// await SiteManager.instance.switchServer('asmr.one', 'mirror-200');
///
/// // 查询某站点所有服务器健康状态
/// final results = await SiteManager.instance.checkAllServerHealth('asmr.one');
///
/// // 找出所有支持"评论提交"功能的站点
/// final canSubmitReview = SiteManager.instance.sitesWithFeature(SiteFeature.submitReview);
/// ```
class SiteManager {
  SiteManager._();

  static final SiteManager instance = SiteManager._();

  final Map<String, _SiteEntry> _sites = {};

  /// 当前激活站点 ID（用于无指定站点时的默认调度）
  String? activeId;

  /// 注册站点。重复 ID 会抛出 [StateError]。
  ///
  /// [info] 站点元信息；[api] 站点实现对象（[SiteApi] 子类）。
  void register({required SiteInfo info, required SiteApi api}) {
    final id = info.id;
    if (_sites.containsKey(id)) {
      throw StateError('站点 $id 已注册');
    }
    _sites[id] = _SiteEntry(info: info, api: api);
    // 首个注册站点自动设为激活
    activeId ??= id;
  }

  /// 注销站点
  void unregister(String id) {
    _sites.remove(id);
    if (activeId == id) {
      activeId = _sites.keys.isNotEmpty ? _sites.keys.first : null;
    }
  }

  /// 根据 ID 获取站点实现对象
  SiteApi? get(String id) => _sites[id]?.api;

  /// 根据 ID 获取站点元信息
  SiteInfo? infoOf(String id) => _sites[id]?.info;

  /// 获取所有已注册站点的实现对象
  List<SiteApi> get all =>
      _sites.values.map((e) => e.api).toList(growable: false);

  /// 获取所有已注册站点的元信息
  List<SiteInfo> get allInfo =>
      _sites.values.map((e) => e.info).toList(growable: false);

  /// 获取当前激活站点的实现对象
  SiteApi? get active => activeId == null ? null : _sites[activeId]?.api;

  /// 获取当前激活站点的元信息
  SiteInfo? get activeInfo =>
      activeId == null ? null : _sites[activeId]?.info;

  /// 返回所有支持指定功能的站点
  ///
  /// ```dart
  /// final canSearch = SiteManager.instance.sitesWithFeature(SiteFeature.search);
  /// ```
  List<SiteApi> sitesWithFeature(SiteFeature feature) {
    return _sites.values
        .map((e) => e.api)
        .where((api) => api.supports(feature))
        .toList(growable: false);
  }

  /// 判断指定站点是否支持某功能
  bool supports(String siteId, SiteFeature feature) {
    final api = get(siteId);
    return api != null && api.supports(feature);
  }

  // ─── 服务器管理 ────────────────────────────────────────────────

  /// 获取指定站点的所有服务器
  List<ServerInfo> serversOf(String siteId) =>
      infoOf(siteId)?.servers ?? const [];

  /// 获取指定站点当前使用的服务器。
  ///
  /// - 若站点声明 [SiteFeature.serverSwitch]，返回 [SiteApi.currentServer]
  /// - 否则若站点声明了 [SiteInfo.servers]，返回 [SiteInfo.defaultServer]
  /// - 都没有则返回 null
  ServerInfo? currentServerOf(String siteId) {
    final api = get(siteId);
    if (api != null && api.supports(SiteFeature.serverSwitch)) {
      return api.currentServer;
    }
    return infoOf(siteId)?.defaultServer;
  }

  /// 切换指定站点到指定服务器。
  ///
  /// 需站点声明 [SiteFeature.serverSwitch]，否则抛出 [UnsupportedError]。
  /// [serverId] 必须是站点 [SiteInfo.servers] 中某项的 [ServerInfo.id]。
  Future<void> switchServer(String siteId, String serverId) async {
    final api = get(siteId);
    if (api == null || !api.supports(SiteFeature.serverSwitch)) {
      throw UnsupportedError('站点 $siteId 不支持服务器切换');
    }
    final server = serversOf(siteId).firstWhere(
      (s) => s.id == serverId,
      orElse: () => throw ArgumentError('站点 $siteId 不存在服务器 $serverId'),
    );
    await api.switchServer(server);
  }

  /// 检查指定站点的指定服务器健康状态。
  ///
  /// 需站点声明 [SiteFeature.healthCheck]，否则抛出 [UnsupportedError]。
  Future<ServerHealth> checkServerHealth(
    String siteId,
    String serverId,
  ) async {
    final api = get(siteId);
    if (api == null || !api.supports(SiteFeature.healthCheck)) {
      throw UnsupportedError('站点 $siteId 不支持健康检查');
    }
    final server = serversOf(siteId).firstWhere(
      (s) => s.id == serverId,
      orElse: () => throw ArgumentError('站点 $siteId 不存在服务器 $serverId'),
    );
    return api.checkHealth(server);
  }

  /// 批量检查指定站点所有服务器的健康状态。
  ///
  /// 需站点声明 [SiteFeature.healthCheck]，否则抛出 [UnsupportedError]。
  Future<List<ServerHealth>> checkAllServerHealth(String siteId) async {
    final api = get(siteId);
    if (api == null || !api.supports(SiteFeature.healthCheck)) {
      throw UnsupportedError('站点 $siteId 不支持健康检查');
    }
    final servers = serversOf(siteId);
    if (servers.isEmpty) return const [];
    return api.checkAllHealth(servers);
  }

  /// 为指定站点自动选择第一个健康的服务器并切换过去。
  ///
  /// 检查顺序：[SiteInfo.defaultServer] 优先，然后按 [SiteInfo.servers] 顺序。
  /// 若全部不健康，保留当前服务器并返回 null。
  ///
  /// 返回选中的 [ServerInfo]；若站点不支持切换 / 健康检查 / 全部不健康，返回 null。
  Future<ServerInfo?> selectHealthyServer(String siteId) async {
    final api = get(siteId);
    if (api == null) return null;
    if (!api.supports(SiteFeature.healthCheck) ||
        !api.supports(SiteFeature.serverSwitch)) {
      return null;
    }

    final servers = serversOf(siteId);
    if (servers.isEmpty) return null;

    final healths = await api.checkAllHealth(servers);
    ServerHealth? healthOf(String serverId) {
      for (final h in healths) {
        if (h.serverId == serverId) return h;
      }
      return null;
    }

    // 优先尝试默认服务器
    final defaultServer = infoOf(siteId)?.defaultServer;
    if (defaultServer != null) {
      final h = healthOf(defaultServer.id);
      if (h != null && h.isHealthy) {
        await api.switchServer(defaultServer);
        return defaultServer;
      }
    }

    // 默认不健康，按列表顺序找第一个健康的
    for (final server in servers) {
      final h = healthOf(server.id);
      if (h != null && h.isHealthy) {
        await api.switchServer(server);
        return server;
      }
    }

    return null;
  }

  /// 应用启动时批量健康检查所有站点并自动选择健康服务器。
  ///
  /// 对所有声明了 [SiteInfo.servers] 且同时支持
  /// [SiteFeature.healthCheck] 与 [SiteFeature.serverSwitch] 的站点，
  /// 调用 [selectHealthyServer] 自动切换到健康服务器。
  ///
  /// 返回每个站点的选中结果（`siteId → 选中 server`，未选中为 null）。
  Future<Map<String, ServerInfo?>> bootstrapHealthyServers() async {
    final result = <String, ServerInfo?>{};
    for (final info in allInfo) {
      if (info.servers.isEmpty) continue;
      final api = get(info.id);
      if (api == null) continue;
      if (!api.supports(SiteFeature.healthCheck) ||
          !api.supports(SiteFeature.serverSwitch)) {
        continue;
      }
      result[info.id] = await selectHealthyServer(info.id);
    }
    return result;
  }

  // ─── 其他 ──────────────────────────────────────────────────────

  /// 判断是否存在已注册站点
  bool contains(String id) => _sites.containsKey(id);

  /// 清空所有注册站点
  void clear() {
    _sites.clear();
    activeId = null;
  }
}
