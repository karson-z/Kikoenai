import 'package:dio/dio.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../../api/server_health.dart';
import '../../api/server_info.dart';
import '../../api/site_api.dart';
import '../../api/site_feature.dart';
import '../../api/site_info.dart';
import '../../api/site_plugin.dart';
import '../../network/exception.dart';
import '../../network/http_client.dart';
import '../../network/request_config.dart';

/// Adapter for a user-owned Kikoeru Express server.
///
/// The implementation targets the canonical Kikoeru Express 0.6.x API. A
/// configured server may point either to the web root (`https://host:port`) or
/// directly to its API root (`https://host:port/api`).
class KikoeruSiteApi extends SiteApi {
  KikoeruSiteApi({
    required List<ServerInfo> servers,
    SitesHttpClient? httpClient,
    ServerInfo? initialServer,
    Future<String?> Function()? tokenProvider,
  }) : assert(servers.isNotEmpty),
       _servers = List<ServerInfo>.unmodifiable(servers),
       _currentServer = initialServer ?? servers.first,
       _tokenProvider = tokenProvider,
       _http =
           httpClient ??
           SitesHttpClient(
             config: RequestConfig(
               baseUrl: apiBaseUrlFor(initialServer ?? servers.first),
               referer: webBaseUrlFor(initialServer ?? servers.first),
               enableCookie: true,
               useProxy: (initialServer ?? servers.first).useProxy,
             ),
             tokenProvider: tokenProvider,
           ) {
    for (final server in _servers) {
      apiBaseUrlFor(server);
    }
    if (!_servers.any((server) => server.id == _currentServer.id)) {
      throw ArgumentError('初始服务器不属于 Kikoeru 运行时服务器列表');
    }
  }

  static const SiteInfo info = SiteInfo(
    id: 'kikoeru',
    name: 'Kikoeru 自建站',
    version: '0.6.x',
  );

  static final SitePlugin plugin = SitePlugin(
    info: info,
    createApi: (context) {
      final servers = context.resolveServers(info);
      if (servers.isEmpty) {
        throw StateError('Kikoeru 至少需要配置一个服务器');
      }
      final initialServer = context.resolveInitialServer(info) ?? servers.first;
      final tokenFor = context.tokenFor;
      final recovery = context.recoverReadRequest;
      final unauthorized = context.onUnauthorized;
      final Future<String?> Function()? tokenProvider = tokenFor == null
          ? null
          : () => tokenFor(info.id);
      final client = SitesHttpClient(
        config: RequestConfig(
          baseUrl: apiBaseUrlFor(initialServer),
          referer: webBaseUrlFor(initialServer),
          enableLogger: true,
          enableCookie: true,
          useProxy: initialServer.useProxy,
          onUnauthorized: unauthorized == null
              ? null
              : (_) => unauthorized(info.id),
        ),
        tokenProvider: tokenProvider,
        readRequestRecovery: recovery == null
            ? null
            : (exception) => recovery(info.id, exception),
      );
      return KikoeruSiteApi(
        servers: servers,
        httpClient: client,
        initialServer: initialServer,
        tokenProvider: tokenProvider,
      );
    },
  );

  final SitesHttpClient _http;
  final List<ServerInfo> _servers;
  final Future<String?> Function()? _tokenProvider;
  ServerInfo _currentServer;

  @override
  SitesHttpClient get httpClient => _http;

  @override
  Set<SiteFeature> get supportedFeatures => const {
    SiteFeature.search,
    SiteFeature.popular,
    SiteFeature.circles,
    SiteFeature.tags,
    SiteFeature.vas,
    SiteFeature.detail,
    SiteFeature.tracks,
    SiteFeature.reviews,
    SiteFeature.submitReview,
    SiteFeature.login,
    SiteFeature.serverSwitch,
    SiteFeature.healthCheck,
  };

  /// Turns a configured web root or API root into the actual Dio base URL.
  static String apiBaseUrlFor(ServerInfo server) {
    final uri = _validatedServerUri(server);
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (!path.endsWith('/api')) path = '$path/api';
    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  /// Returns the web root corresponding to [server].
  static String webBaseUrlFor(ServerInfo server) {
    final uri = _validatedServerUri(server);
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/api')) path = path.substring(0, path.length - 4);
    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  static Uri _validatedServerUri(ServerInfo server) {
    final uri = Uri.tryParse(server.resolvedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('Kikoeru 服务器地址无效: ${server.resolvedBaseUrl}');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw FormatException('Kikoeru 服务器只支持 HTTP/HTTPS: ${uri.scheme}');
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw FormatException('Kikoeru 服务器地址不能包含 query 或 fragment');
    }
    return uri;
  }

  // ─── Discovery ──────────────────────────────────────────────

  @override
  Future<PagedResult<Work>> searchWorks(SearchWorksRequest req) async {
    final keyword = _normalizeSearchKeyword(req.keyword);
    final field = req.extra['field'] as String?;
    final fieldId = req.extra['fieldId'] ?? req.extra['id'];
    final isRestricted =
        const {'circle', 'tag', 'va'}.contains(field) && fieldId != null;
    final path = isRestricted
        ? '/${field}s/$fieldId/works'
        : keyword.isEmpty
        ? '/works'
        : '/search/${Uri.encodeComponent(keyword)}';

    Map<String, dynamic> response;
    try {
      response = await _http.get<Map<String, dynamic>>(
        path,
        queryParameters: _listQuery(req),
      );
    } on SitesNetworkException catch (error) {
      // Some maintained 0.6.x forks changed `/search/:keyword` into
      // `/search?keyword=...`. Retry only when the canonical route is absent.
      if (error.code != SitesExceptionCode.notFound ||
          !path.startsWith('/search/')) {
        rethrow;
      }
      response = await _http.get<Map<String, dynamic>>(
        '/search',
        queryParameters: {..._listQuery(req), 'keyword': keyword},
      );
    }
    return _parsePagedWorks(response);
  }

  @override
  Future<PagedResult<Work>> getPopularWorks(SearchWorksRequest req) async {
    if (_normalizeSearchKeyword(req.keyword).isNotEmpty) {
      return searchWorks(
        req.copyWith(order: req.order ?? 'dl_count', sort: req.sort ?? 'desc'),
      );
    }
    final response = await _http.get<Map<String, dynamic>>(
      '/works',
      queryParameters: {
        ..._listQuery(req),
        'order': req.order ?? 'dl_count',
        'sort': req.sort ?? 'desc',
      },
    );
    return _parsePagedWorks(response);
  }

  Map<String, dynamic> _listQuery(SearchWorksRequest req) => {
    'page': req.page,
    if (req.order != null) 'order': req.order,
    if (req.sort != null) 'sort': req.sort,
    if (req.seed != null) 'seed': req.seed,
  };

  @override
  Future<List<Circle>> getCircles() =>
      _getMetadataList('/circles/', Circle.fromJson);

  @override
  Future<List<Tag>> getTags() => _getMetadataList('/tags/', Tag.fromJson);

  @override
  Future<List<VA>> getVas() => _getMetadataList('/vas/', VA.fromJson);

  Future<List<T>> _getMetadataList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _http.get<List<dynamic>>(path);
    return response
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  /// Fetches one circle, tag, or voice-actor record by its native ID.
  Future<Map<String, dynamic>> getMetadata({
    required String field,
    required Object id,
  }) {
    if (!const {'circle', 'tag', 'va'}.contains(field)) {
      throw ArgumentError.value(field, 'field', '必须是 circle/tag/va');
    }
    return _http.get<Map<String, dynamic>>('/${field}s/$id');
  }

  // ─── Work details and media ─────────────────────────────────

  @override
  Future<Work> getWorkDetail(String workId) async {
    final id = _requireNumericWorkId(workId);
    final response = await _http.get<Map<String, dynamic>>('/work/$id');
    return _tagWork(Work.fromJson(response), token: await _readToken());
  }

  @override
  Future<List<FileNode>> getWorkTracks(String workId) async {
    final id = _requireNumericWorkId(workId);
    final response = await _http.get<List<dynamic>>('/tracks/$id');
    final token = await _readToken();
    return response
        .map(
          (item) => FileNode.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .map((node) => _tagNode(node, workId: id, token: token))
        .toList(growable: false);
  }

  FileNode _tagNode(FileNode node, {required int workId, String? token}) {
    final children = node.children
        ?.map((child) => _tagNode(child, workId: workId, token: token))
        .toList(growable: false);
    final hash = node.hash;
    final streamPath =
        node.mediaStreamUrl ??
        (hash == null ? null : '/api/media/stream/$hash');
    final downloadPath =
        node.mediaDownloadUrl ??
        (hash == null ? null : '/api/media/download/$hash');
    return node.copyWith(
      children: children,
      mediaStreamUrl: streamPath == null
          ? null
          : _resourceUrl(streamPath, token: token),
      mediaDownloadUrl: downloadPath == null
          ? null
          : _resourceUrl(downloadPath, token: token),
      workId: workId,
      source: NodeSource.asmrServer,
      siteId: info.id,
      remoteId: workId.toString(),
    );
  }

  /// Checks whether the specified media item has a matching LRC file.
  Future<Map<String, dynamic>> checkLyric({
    required String workId,
    required int index,
  }) => _http.get<Map<String, dynamic>>(
    '/media/check-lrc/${_requireNumericWorkId(workId)}/$index',
  );

  Future<String> mediaStreamUrl({
    required String workId,
    required int index,
  }) async => _resourceUrl(
    '/api/media/stream/${_requireNumericWorkId(workId)}/$index',
    token: await _readToken(),
  );

  Future<String> mediaDownloadUrl({
    required String workId,
    required int index,
  }) async => _resourceUrl(
    '/api/media/download/${_requireNumericWorkId(workId)}/$index',
    token: await _readToken(),
  );

  // ─── Reviews ────────────────────────────────────────────────

  @override
  Future<PagedResult<Work>> fetchReviews(ReviewQueryParams params) async {
    final response = await _http.get<Map<String, dynamic>>(
      '/review',
      queryParameters: {
        'page': params.page,
        'order': params.order,
        'sort': params.sort,
        if (params.filter != null) 'filter': params.filter,
      },
    );
    return _parsePagedWorks(response);
  }

  @override
  Future<Map<String, dynamic>> submitReview({
    required String workId,
    required UserWorkStatus workStatus,
  }) {
    return _http.put<Map<String, dynamic>>(
      '/review',
      queryParameters: const {'starOnly': false},
      data: {
        'work_id': _requireNumericWorkId(workId),
        if (workStatus.rating > 0) 'rating': workStatus.rating,
        if (workStatus.reviewText.isNotEmpty)
          'review_text': workStatus.reviewText,
        if (workStatus.progress != WorkProgress.unknown)
          'progress': workStatus.progress.toJson(),
      },
    );
  }

  /// Deletes the current user's review/mark for a work.
  Future<void> deleteReview(String workId) async {
    await _http.delete<Map<String, dynamic>>(
      '/review',
      queryParameters: {'work_id': _requireNumericWorkId(workId)},
    );
  }

  // ─── Authentication ─────────────────────────────────────────

  @override
  Future<AuthResponse> login(LoginParams loginParams) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/me',
      data: {'name': loginParams.username, 'password': loginParams.password},
    );
    final token = response['token'] as String?;
    if (token == null || token.isEmpty) {
      throw SitesNetworkException(
        response['error'] as String? ?? 'Kikoeru 登录失败',
      );
    }
    return AuthResponse(
      token: token,
      user: User(name: loginParams.username, token: token, loggedIn: true),
    );
  }

  /// Returns the current account and whether authentication is enabled.
  Future<Map<String, dynamic>> getSessionInfo() =>
      _http.get<Map<String, dynamic>>('/auth/me');

  // ─── Server management ──────────────────────────────────────

  @override
  ServerInfo get currentServer => _currentServer;

  @override
  Future<void> switchServer(ServerInfo server) async {
    final configured = _servers.where((item) => item.id == server.id);
    if (configured.isEmpty) {
      throw ArgumentError('Kikoeru 不存在服务器: ${server.id}');
    }
    final target = configured.first;
    if (_currentServer == target) return;
    _currentServer = target;
    _http.updateConnection(
      baseUrl: apiBaseUrlFor(target),
      useProxy: target.useProxy,
    );
  }

  @override
  Future<ServerHealth> checkHealth(ServerInfo server) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _http.dio.get<dynamic>(
        '${apiBaseUrlFor(server)}/health',
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
    } catch (error) {
      stopwatch.stop();
      return ServerHealth(
        serverId: server.id,
        status: HealthStatus.unhealthy,
        errorMessage: error.toString(),
        checkedAt: DateTime.now(),
      );
    }
  }

  // ─── Kikoeru-specific administrative API ────────────────────

  Future<Map<String, dynamic>> getVersionInfo() =>
      _http.get<Map<String, dynamic>>('/version');

  Future<Map<String, dynamic>> getSharedConfig() =>
      _http.get<Map<String, dynamic>>('/config/shared');

  Future<Map<String, dynamic>> getAdminConfig() =>
      _http.get<Map<String, dynamic>>('/config/admin');

  Future<Map<String, dynamic>> updateAdminConfig(Map<String, dynamic> config) =>
      _http.put<Map<String, dynamic>>(
        '/config/admin',
        data: {'config': config},
      );

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _http.get<Map<String, dynamic>>(
      '/credentials/users',
    );
    final users = response['users'] as List<dynamic>? ?? const [];
    return users
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> createUser({
    required String name,
    required String password,
    String group = 'user',
  }) async {
    await _http.post<Map<String, dynamic>>(
      '/credentials/user',
      data: {'name': name, 'password': password, 'group': group},
    );
  }

  Future<void> updateUserPassword({
    required String name,
    required String newPassword,
  }) async {
    await _http.put<Map<String, dynamic>>(
      '/credentials/user',
      data: {'name': name, 'newPassword': newPassword},
    );
  }

  Future<void> deleteUsers(List<String> names) async {
    await _http.delete<Map<String, dynamic>>(
      '/credentials/user',
      data: {
        'users': names.map((name) => {'name': name}).toList(growable: false),
      },
    );
  }

  // ─── Parsing and URL helpers ─────────────────────────────────

  Future<PagedResult<Work>> _parsePagedWorks(
    Map<String, dynamic> response,
  ) async {
    final token = await _readToken();
    final rawWorks = response['works'] as List<dynamic>? ?? const [];
    final works = rawWorks
        .map((item) => Work.fromJson(Map<String, dynamic>.from(item as Map)))
        .map((work) => _tagWork(work, token: token))
        .toList(growable: false);
    final rawPagination = response['pagination'];
    final pagination = rawPagination is Map
        ? Pagination.fromJson(Map<String, dynamic>.from(rawPagination))
        : Pagination(
            currentPage: 1,
            pageSize: works.length,
            totalCount: works.length,
          );
    return PagedResult(items: works, pagination: pagination);
  }

  Work _tagWork(Work work, {String? token}) {
    final id = work.id.toString();
    return work.copyWith(
      siteId: info.id,
      remoteId: id,
      mainCoverUrl: coverUrl(id, token: token),
      thumbnailCoverUrl: coverUrl(id, type: '240x240', token: token),
      samCoverUrl: coverUrl(id, type: 'sam', token: token),
    );
  }

  String coverUrl(String workId, {String type = 'main', String? token}) {
    return _resourceUrl(
      '/api/cover/${_requireNumericWorkId(workId)}',
      token: token,
      query: {'type': type},
    );
  }

  String _resourceUrl(
    String input, {
    String? token,
    Map<String, String> query = const {},
  }) {
    final inputUri = Uri.tryParse(input);
    Uri uri;
    if (inputUri?.hasScheme == true) {
      uri = inputUri!;
    } else {
      var relative = input;
      final usesApiRoot = relative.startsWith('/api/');
      final baseUri = Uri.parse(
        usesApiRoot
            ? apiBaseUrlFor(_currentServer)
            : webBaseUrlFor(_currentServer),
      );
      if (usesApiRoot) relative = relative.substring(4);
      if (!relative.startsWith('/')) relative = '/$relative';
      uri = baseUri.replace(path: '${baseUri.path}$relative');
    }
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            ...query,
            if (token != null && token.isNotEmpty) 'token': token,
          },
        )
        .toString();
  }

  Future<String?> _readToken() =>
      _tokenProvider?.call() ?? Future<String?>.value();

  int _requireNumericWorkId(String workId) {
    final value = int.tryParse(workId);
    if (value == null) {
      throw FormatException('Kikoeru 作品 ID 必须是整数: $workId');
    }
    return value;
  }

  String _normalizeSearchKeyword(String? keyword) {
    if (keyword == null || keyword.trim().isEmpty) return '';
    var decoded = keyword;
    try {
      decoded = Uri.decodeComponent(keyword);
    } on FormatException {
      // The value may already be decoded; use it as-is.
    }
    final tagPattern = RegExp(
      r'\$-?(?:tag|va|circle|age|duration|rate|price|sell|lang):([^$]+)\$',
    );
    final tagNames = tagPattern
        .allMatches(decoded)
        .map((match) => match.group(1)!.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final plainText = decoded.replaceAll(tagPattern, ' ').trim();
    if (plainText.isNotEmpty) return plainText;
    return tagNames.isEmpty ? '' : tagNames.first;
  }
}
