import 'package:dio/dio.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../../api/listen_event_type.dart';
import '../../api/server_health.dart';
import '../../api/server_info.dart';
import '../../api/site_api.dart';
import '../../api/site_feature.dart';
import '../../api/site_info.dart';
import '../../api/site_plugin.dart';
import '../../network/exception.dart';
import '../../network/http_client.dart';

/// asmr.one 站点适配实现。
///
/// 通过 [supportedFeatures] 声明当前支持的全部功能点，业务层通过
/// [SiteApi.supports] 判断子功能是否可用，无需引入大量 capability 接口。
///
/// 站点内置 4 个服务器镜像，应用启动时由
/// `SiteManager.bootstrapHealthyServers()` 自动选择健康服务器；
/// 运行时可通过 `SiteManager.switchServer(...)` 无缝切换。
///
/// 外部站点元数据爬取（DLSite / HVDB）不属于本站点能力，
/// 业务层如需补全元数据请直接使用 `DlSiteScraper.scrapeAll` 等共用工具。
///
/// 通过 [SiteManager.instance.register] 注册：
///
/// ```dart
/// SiteManager.instance.register(
///   info: AsmrOneSiteApi.info,
///   api: AsmrOneSiteApi(),
/// );
/// ```
class AsmrOneSiteApi extends SiteApi {
  AsmrOneSiteApi({SitesHttpClient? httpClient, ServerInfo? initialServer})
    : _http = httpClient ?? SitesHttpClient.instance,
      _currentServer = initialServer ?? _defaultServers.first;

  final SitesHttpClient _http;

  /// 暴露 HTTP 客户端（供业务层直接 getBytes 等场景使用）
  SitesHttpClient get httpClient => _http;

  /// 当前使用的服务器
  ServerInfo _currentServer;

  /// asmr.one 服务器镜像列表（与 app 端 EnvironmentConfig._candidates 对齐）
  static const List<ServerInfo> _defaultServers = [
    ServerInfo(
      id: 'mirror-200',
      baseUrl: 'https://api.asmr-200.com/api',
      label: 'Mirror-200 (推荐)',
      region: 'CN',
      isDefault: true,
    ),
    ServerInfo(
      id: 'main',
      baseUrl: 'https://api.asmr.one/api',
      label: 'Main (ASMR.ONE)',
      region: 'CN',
    ),
    ServerInfo(
      id: 'mirror-100',
      baseUrl: 'https://api.asmr-100.com/api',
      label: 'Mirror-100',
      region: 'CN',
    ),
    ServerInfo(
      id: 'mirror-300',
      baseUrl: 'https://api.asmr-300.com/api',
      label: 'Mirror-300',
      region: 'CN',
    ),
  ];

  /// 站点元信息（包含所有服务器镜像）
  static const SiteInfo info = SiteInfo(
    id: 'asmr.one',
    name: 'ASMR.ONE',
    version: '1.0.0',
    servers: _defaultServers,
  );

  static final SitePlugin plugin = SitePlugin(
    info: info,
    createApi: (context) => AsmrOneSiteApi(
      httpClient: context.httpClient,
      initialServer: context.initialServer,
    ),
  );

  /// 当前站点支持的功能集合
  @override
  Set<SiteFeature> get supportedFeatures => const {
    // 检索
    SiteFeature.search,
    SiteFeature.popular,
    SiteFeature.recommend,
    SiteFeature.circles,
    SiteFeature.tags,
    SiteFeature.vas,
    // 详情与音轨
    SiteFeature.detail,
    SiteFeature.tracks,
    // 收藏
    SiteFeature.playlists,
    SiteFeature.playlistWorks,
    SiteFeature.playlistWorksByKeyword,
    SiteFeature.defaultMarkTargetPlaylist,
    SiteFeature.addWorksToPlaylist,
    SiteFeature.removeWorksFromPlaylist,
    // 评论
    SiteFeature.reviews,
    SiteFeature.submitReview,
    // 认证
    SiteFeature.login,
    SiteFeature.register,
    // 埋点
    SiteFeature.feedback,
    // 服务器管理
    SiteFeature.serverSwitch,
    SiteFeature.healthCheck,
  };

  // ─── 检索类 ──────────────────────────────────────────

  @override
  Future<PagedResult<Work>> searchWorks(SearchWorksRequest req) async {
    // 有 keyword 时走 /search/{keyword}，无 keyword 时走 /works
    final hasKeyword = req.keyword != null && req.keyword!.isNotEmpty;
    final path = hasKeyword ? '/search/${req.keyword}' : '/works';
    final response = await _http.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        'page': req.page,
        'pageSize': req.pageSize,
        if (req.order != null) 'order': req.order,
        if (req.sort != null) 'sort': req.sort,
        if (req.subtitle != null) 'subtitle': req.subtitle,
        if (req.seed != null) 'seed': req.seed,
        'includeTranslationWorks': req.includeTranslationWorks,
        ...req.extra,
      },
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<PagedResult<Work>> getPopularWorks(SearchWorksRequest req) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/recommender/popular',
      data: {
        'keyword': req.keyword ?? ' ',
        'page': req.page,
        'pageSize': req.pageSize,
        'subtitle': req.subtitle ?? 0,
        'localSubtitledWorks': req.localSubtitledWorks,
        'withPlaylistStatus': req.withPlaylistStatus ?? [],
      },
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<PagedResult<Work>> getRecommendedWorks(SearchWorksRequest req) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/recommender/recommend-for-user',
      data: {
        'keyword': req.keyword ?? ' ',
        'recommenderUuid': req.recommenderUuid ?? '',
        'page': req.page,
        'pageSize': req.pageSize,
        'subtitle': req.subtitle ?? 0,
        'localSubtitledWorks': req.localSubtitledWorks,
        'withPlaylistStatus': req.withPlaylistStatus ?? [],
      },
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<List<Circle>> getCircles() async {
    final response = await _http.get<List<dynamic>>('/circles/');
    return response
        .map((e) => Circle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Tag>> getTags() async {
    final response = await _http.get<List<dynamic>>('/tags/');
    return response
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VA>> getVas() async {
    final response = await _http.get<List<dynamic>>('/vas/');
    return response.map((e) => VA.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── 详情与音轨 ──────────────────────────────────────

  @override
  Future<Work> getWorkDetail(String workId) async {
    _requireNumericWorkId(workId);
    final response = await _http.get<Map<String, dynamic>>('/work/$workId');
    return _tagWork(Work.fromJson(response));
  }

  @override
  Future<List<FileNode>> getWorkTracks(String workId) async {
    final numericWorkId = _requireNumericWorkId(workId);
    final response = await _http.get<List<dynamic>>(
      '/tracks/$workId',
      queryParameters: {'v': 2},
    );
    return response
        .map((json) => FileNode.fromJson(json as Map<String, dynamic>))
        .map(
          (node) => node.copyWith(
            source: NodeSource.asmrServer,
            workId: numericWorkId,
            siteId: info.id,
            remoteId: workId,
          ),
        )
        .toList();
  }

  // ─── 收藏 / 播放列表 ────────────────────────────────

  @override
  Future<PagedResult<Playlist>> fetchPlaylists({
    required int page,
    int pageSize = 20,
    String filterBy = 'all',
  }) async {
    final response = await _http.get<Map<String, dynamic>>(
      '/playlist/get-playlists',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'filterBy': filterBy,
      },
    );
    final parsed = PlaylistListResponse.fromJson(response);
    return PagedResult<Playlist>(
      items: parsed.playlists,
      pagination: parsed.pagination,
    );
  }

  @override
  Future<PagedResult<Work>> fetchPlaylistWorks({
    required String playlistId,
    required int page,
    int pageSize = 12,
  }) async {
    final response = await _http.get<Map<String, dynamic>>(
      '/playlist/get-playlist-works',
      queryParameters: {'id': playlistId, 'page': page, 'pageSize': pageSize},
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<PagedResult<Work>> fetchPlaylistWorksByKeyword(
    PlaylistWorksRequest request,
  ) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/playlist/get-playlist-works-by-keyword',
      data: request.toJson(),
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<Playlist> fetchDefaultMarkTargetPlaylist() async {
    final response = await _http.get<Map<String, dynamic>>(
      '/playlist/get-default-mark-target-playlist',
    );
    return Playlist.fromJson(response);
  }

  @override
  Future<void> addWorksToPlaylist({
    required String playlistId,
    required List<String> workIds,
  }) async {
    await _http.post<Map<String, dynamic>>(
      '/playlist/add-works-to-playlist',
      data: {
        'playlistId': playlistId,
        'works': workIds.map(_requireNumericWorkId).toList(growable: false),
      },
    );
  }

  @override
  Future<void> removeWorksFromPlaylist({
    required String playlistId,
    required List<String> workIds,
  }) async {
    await _http.post<Map<String, dynamic>>(
      '/playlist/remove-works-from-playlist',
      data: {
        'playlistId': playlistId,
        'works': workIds.map(_requireNumericWorkId).toList(growable: false),
      },
    );
  }

  // ─── 评论 ──────────────────────────────────────────

  @override
  Future<PagedResult<Work>> fetchReviews(ReviewQueryParams params) async {
    final queryMap = <String, dynamic>{
      'order': params.order,
      'sort': params.sort,
      'page': params.page,
      'filter': params.filter,
    };
    queryMap.removeWhere((key, value) => value == null);

    final response = await _http.get<Map<String, dynamic>>(
      '/review',
      queryParameters: queryMap,
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<Map<String, dynamic>> submitReview({
    required String workId,
    required UserWorkStatus workStatus,
  }) async {
    final Map<String, dynamic> requestData = {
      'work_id': _requireNumericWorkId(workId),
    };

    if (workStatus.rating > 0) {
      requestData['rating'] = workStatus.rating;
    }
    if (workStatus.reviewText.isNotEmpty) {
      requestData['review_text'] = workStatus.reviewText;
    }
    if (workStatus.progress != WorkProgress.unknown) {
      requestData['progress'] = workStatus.progress.toJson();
    }

    return _http.put<Map<String, dynamic>>('/review', data: requestData);
  }

  // ─── 认证 ──────────────────────────────────────────

  @override
  Future<AuthResponse> login(LoginParams loginParams) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/me',
      data: {'name': loginParams.username, 'password': loginParams.password},
    );
    return _parseAuthResponse(response, fallbackMessage: '登录失败');
  }

  @override
  Future<AuthResponse> register(RegisterRequestModel reg) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/register',
      data: reg.toJson(),
    );
    return _parseAuthResponse(response, fallbackMessage: '注册失败');
  }

  // ─── 埋点 ──────────────────────────────────────────

  @override
  Future<void> submitPlaybackFeedback({
    required String workId,
    required String recommendUuid,
    required ListenEventType type,
  }) async {
    await _http.post<Map<String, dynamic>>(
      '/recommender/feedback',
      data: {
        'itemId': workId,
        'recommendUuid': recommendUuid,
        'type': type.type,
      },
    );
  }

  // ─── 服务器管理 ──────────────────────────────────────

  @override
  ServerInfo get currentServer => _currentServer;

  @override
  Future<void> switchServer(ServerInfo server) async {
    // 仅允许切换到站点声明的服务器，避免外部传入伪造 ServerInfo
    if (!_defaultServers.any((s) => s.id == server.id)) {
      throw ArgumentError('站点 asmr.one 不存在服务器: ${server.id}');
    }
    if (_currentServer.id == server.id) return;
    _currentServer = server;
    _http.updateBaseUrl(server.baseUrl);
  }

  @override
  Future<ServerHealth> checkHealth(ServerInfo server) async {
    final url = '${server.baseUrl}/health?cache=false';
    final stopwatch = Stopwatch()..start();
    try {
      await _http.dio.get<dynamic>(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      stopwatch.stop();
      return ServerHealth(
        serverId: server.id,
        status: HealthStatus.healthy,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      return ServerHealth(
        serverId: server.id,
        status: HealthStatus.unhealthy,
        errorMessage: e.toString(),
        checkedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<ServerHealth>> checkAllHealth(List<ServerInfo> servers) {
    return Future.wait(servers.map(checkHealth));
  }

  /// 统一解析 `{ works: [...], pagination: {...} }` 响应为 [PagedResult<Work>]
  PagedResult<Work> _parsePagedWorks(Map<String, dynamic> response) {
    final listData = response['works'] as List<dynamic>? ?? [];
    final works = listData
        .map((e) => _tagWork(Work.fromJson(e as Map<String, dynamic>)))
        .toList();

    final paginationJson = response['pagination'] as Map<String, dynamic>?;
    final pagination = paginationJson == null
        ? Pagination(
            currentPage: 1,
            pageSize: works.length,
            totalCount: works.length,
          )
        : Pagination.fromJson(paginationJson);

    return PagedResult<Work>(items: works, pagination: pagination);
  }

  Work _tagWork(Work work) =>
      work.copyWith(siteId: info.id, remoteId: work.id.toString());

  int _requireNumericWorkId(String workId) {
    final parsed = int.tryParse(workId);
    if (parsed == null) {
      throw FormatException('ASMR.ONE 作品 ID 必须是整数: $workId');
    }
    return parsed;
  }

  /// 解析 [AuthResponse]，失败时抛出 [SitesNetworkException]
  AuthResponse _parseAuthResponse(
    Map<String, dynamic>? data, {
    required String fallbackMessage,
  }) {
    if (data == null) {
      throw SitesNetworkException(fallbackMessage);
    }
    final authResponse = AuthResponse.fromJson(data);
    if (!authResponse.isSuccess) {
      throw SitesNetworkException(authResponse.error ?? fallbackMessage);
    }
    return authResponse;
  }
}
