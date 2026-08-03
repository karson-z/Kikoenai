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

/// asmr.gay（asmr.pw）站点适配实现。
///
/// 这是一个基于 Alist 的文件系统型站点，与 asmr.one（数据库型）不同，
/// 内容按目录树组织，通过 `/api/fs/list` 按路径分页浏览。
///
/// 站点内置 4 个服务器镜像，应用启动时由
/// `SiteRegistry.bootstrapHealthyServers()` 自动选择健康服务器；
/// 运行时可通过 `SiteRegistry.switchServer(...)` 无缝切换。
///
/// 健康检查直接请求服务器根域名（Alist 站点无 `/health` 端点）。
class AsmrGaySiteApi extends SiteApi {
  AsmrGaySiteApi({
    SitesHttpClient? httpClient,
    ServerInfo? initialServer,
    this.rawBaseUrl = _defaultRawBaseUrl,
  }) : _http = httpClient ?? SitesHttpClient.instance,
       _currentServer = initialServer ?? _defaultServers.first;

  final SitesHttpClient _http;

  /// 暴露 HTTP 客户端（供业务层直接 getBytes 等场景使用）
  SitesHttpClient get httpClient => _http;

  /// 当前使用的服务器
  ServerInfo _currentServer;

  /// Alist 接口前缀
  static const String _apiPrefix = '/api/fs';

  /// 实际存储（CDN）基础 URL。
  ///
  /// Alist `/api/fs/get` 返回的 `raw_url` 形如
  /// `https://asmr.121231234.xyz/asmr6/xxx.m3u8?sign=...`，
  /// 其中 `https://asmr.121231234.xyz` 是固定存储域名，后面的路径与
  /// Alist 路径一致。因此只要知道该基础 URL，即可直接拼接 raw_url，
  /// 无需对每个文件调用 `/api/fs/get`。
  ///
  /// 若该域名后续变更，可修改此值或传 null 回退到 Alist `/d/` 链接
  ///（`/d/<path>` 会 302 跳转到实际 raw_url）。
  final String? rawBaseUrl;

  static const String _defaultRawBaseUrl = 'https://asmr.121231234.xyz';

  /// asmr.gay 服务器镜像列表
  static const List<ServerInfo> _defaultServers = [
    ServerInfo(
      id: 'main',
      baseUrl: 'https://www.asmrgay.com',
      label: '基佬中心桌面 (asmrgay.com)',
      region: 'CN',
      isDefault: true,
    ),
    ServerInfo(
      id: 'net',
      baseUrl: 'https://asmrgay.net',
      label: '备用站 (asmrgay.net)',
      region: 'CN',
    ),
    ServerInfo(
      id: 'pw',
      baseUrl: 'https://www.asmr.pw',
      label: '备用站 (asmr.pw)',
      region: 'CN',
    ),
    ServerInfo(
      id: 'uno',
      baseUrl: 'https://www.asmr.uno',
      label: '备用站 (asmr.uno)',
      region: 'CN',
    ),
  ];

  /// 站点元信息（包含所有服务器镜像）
  static const SiteInfo info = SiteInfo(
    id: 'asmr.gay',
    name: 'ASMR.GAY',
    version: '1.0.0',
    servers: _defaultServers,
  );

  static final SitePlugin plugin = SitePlugin(
    info: info,
    createApi: (context) => AsmrGaySiteApi(
      httpClient: context.httpClient,
      initialServer: context.initialServer,
    ),
  );

  /// 当前站点支持的功能集合
  @override
  Set<SiteFeature> get supportedFeatures => const {
    // 文件系统（Alist 风格）
    SiteFeature.fileSystemBrowse,
    SiteFeature.fileSystemSearch,
    SiteFeature.siteReadme,
    // 服务器管理
    SiteFeature.serverSwitch,
    SiteFeature.healthCheck,
  };

  // ─── 文件系统浏览 ────────────────────────────────────

  @override
  Future<FsBrowseResult> browseFileSystem(FsListRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '$_apiPrefix/list',
      data: {
        'path': request.path,
        'password': request.password,
        'page': request.page,
        'per_page': request.perPage,
        'refresh': request.refresh,
        ...request.extra,
      },
    );
    return _parseBrowseResult(response);
  }

  @override
  Future<FsBrowseResult> searchFileSystem(FsSearchRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '$_apiPrefix/search',
      data: {
        'parent': request.parent,
        'keywords': request.keywords,
        'scope': request.scope,
        'page': request.page,
        'per_page': request.perPage,
        'password': request.password,
        ...request.extra,
      },
    );
    // 搜索响应结构与 list 一致（content + total），复用同一解析。
    return _parseBrowseResult(response);
  }

  @override
  Future<String?> getSiteReadme({String path = '/'}) async {
    // 复用 browseFileSystem 的响应，取 readme 字段。
    // 用最小分页（per_page=1）避免拉取过多目录条目。
    final result = await browseFileSystem(
      FsListRequest(path: path, page: 1, perPage: 1),
    );
    return result.readme;
  }

  /// 浏览文件系统并直接返回 [FileNode] 分页结果。
  ///
  /// 内部调用 [browseFileSystem] 拿到 [FsBrowseResult] 后，
  /// 将 [FsEntry] 列表转换为 [FileNode] 列表，并标记来源
  /// ([NodeSource.asmrGay]、[SiteInfo.id]、完整路径作为 remoteId)。
  ///
  /// 业务层优先使用本方法获取统一的 [FileNode] 视图；
  /// 需要站点 readme 等元信息时再调用 [browseFileSystem] / [getSiteReadme]。
  Future<PagedResult<FileNode>> browseAsFileNodes(
    FsListRequest request,
  ) async {
    final result = await browseFileSystem(request);
    final nodes = toFileNodes(
      result.content,
      parentPath: request.path,
    );
    return PagedResult<FileNode>(
      items: nodes,
      pagination: Pagination(
        currentPage: request.page,
        pageSize: request.perPage,
        totalCount: result.total,
      ),
    );
  }

  /// 搜索文件系统并直接返回 [FileNode] 分页结果。
  ///
  /// 与 [browseAsFileNodes] 对称，搜索结果条目自带 [FsEntry.parent]，
  /// 转换时无需调用方传入父路径。
  Future<PagedResult<FileNode>> searchAsFileNodes(
    FsSearchRequest request,
  ) async {
    final result = await searchFileSystem(request);
    final nodes = toFileNodes(result.content);
    return PagedResult<FileNode>(
      items: nodes,
      pagination: Pagination(
        currentPage: request.page,
        pageSize: request.perPage,
        totalCount: result.total,
      ),
    );
  }

  /// 将 [FsEntry] 批量转换为 [FileNode]，保持目录顺序与原列表一致。
  ///
  /// [parentPath] 为这些条目所属的父目录路径（用于拼接完整路径与标记 folderPath）。
  /// 当条目自身携带 [FsEntry.parent]（如搜索结果）时，优先使用条目的 parent。
  List<FileNode> toFileNodes(
    List<FsEntry> entries, {
    String parentPath = '',
  }) {
    return entries
        .map((e) => toFileNode(e, parentPath: parentPath))
        .toList(growable: false);
  }

  /// 将单个 [FsEntry] 转换为 [FileNode]。
  ///
  /// 转换规则：
  /// - `type` 依据 [FsEntry.isDir] 与文件扩展名（[FileExtensions]）推断
  /// - `source` 标记为 [NodeSource.asmrGay]（asmr.gay 站点 API 资源，
  ///   区别于 [NodeSource.cloudDrive] 的真正云盘协议接入与
  ///   [NodeSource.asmrServer] 的 asmr.one 数据库型站点）
  /// - `siteId` 标记为本站点 id（`asmr.gay`），`remoteId` 用完整路径
  /// - `path` / `folderPath` 携带 Alist 目录路径信息
  /// - 文件节点的 `mediaDownloadUrl` / `mediaStreamUrl` 使用 Alist 标准下载路径 `/d/<path>`
  ///   （带 [FsEntry.sign] 时附加 `?sign=` 参数）
  ///
  /// [parentPath] 为可选参数：搜索结果条目自带 [FsEntry.parent]，
  /// 此时无需传入；list 结果条目不带 parent，需由调用方传入请求路径。
  FileNode toFileNode(FsEntry entry, {String parentPath = ''}) {
    final effectiveParent =
        entry.parent.isNotEmpty ? entry.parent : parentPath;
    final fullPath = NodeFolder.joinPath(effectiveParent, entry.name);
    final isDir = entry.isDir;

    final downloadUrl = isDir ? null : _buildDownloadUrl(fullPath, entry.sign);

    return FileNode(
      type: _resolveNodeType(entry),
      title: entry.name,
      size: entry.size,
      lastModified: entry.modified?.millisecondsSinceEpoch ?? 0,
      source: NodeSource.asmrGay,
      siteId: info.id,
      remoteId: fullPath,
      path: fullPath,
      folderPath: effectiveParent,
      mediaDownloadUrl: downloadUrl,
      mediaStreamUrl: downloadUrl,
      subItemsCount: 0,
    );
  }

  // ─── 服务器管理 ──────────────────────────────────────

  @override
  ServerInfo get currentServer => _currentServer;

  @override
  Future<void> switchServer(ServerInfo server) async {
    // 仅允许切换到站点声明的服务器，避免外部传入伪造 ServerInfo
    if (!_defaultServers.any((s) => s.id == server.id)) {
      throw ArgumentError('站点 asmr.gay 不存在服务器: ${server.id}');
    }
    if (_currentServer.id == server.id) return;
    _currentServer = server;
    _http.updateBaseUrl(server.baseUrl);
  }

  @override
  Future<ServerHealth> checkHealth(ServerInfo server) async {
    // Alist 站点无 /health 端点，直接请求根域名验证连通性
    final url = server.baseUrl;
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

  // ─── 解析 ──────────────────────────────────────────

  /// 解析 Alist `/api/fs/list` 响应。
  ///
  /// 外层结构为 `{ code, message, data }`，data 内才是
  /// [FsBrowseResult] 的字段。
  FsBrowseResult _parseBrowseResult(Map<String, dynamic> response) {
    final code = response['code'];
    if (code != null && code != 200) {
      throw SitesNetworkException(
        response['message'] as String? ?? 'asmr.gay 接口返回错误 (code: $code)',
        code: SitesExceptionCode.serverError,
        context: {'code': code, 'path': '/api/fs/list'},
      );
    }
    final data = response['data'];
    if (data == null) {
      throw const SitesNetworkException(
        'asmr.gay 接口未返回 data',
        code: SitesExceptionCode.parseError,
      );
    }
    return FsBrowseResult.fromJson(data as Map<String, dynamic>);
  }

  /// 依据 [FsEntry.isDir] 与文件扩展名推断 [NodeType]。
  NodeType _resolveNodeType(FsEntry entry) {
    if (entry.isDir) return NodeType.folder;
    final name = entry.name;
    if (FileExtensions.isAudio(name)) return NodeType.audio;
    if (FileExtensions.isVideo(name)) return NodeType.video;
    if (FileExtensions.isImage(name)) return NodeType.image;
    if (FileExtensions.isDocument(name) || FileExtensions.isSubtitle(name)) {
      return NodeType.text;
    }
    return NodeType.other;
  }

  /// 构造可直接播放/下载的 URL。
  ///
  /// 优先使用实际存储（CDN）域名拼接 raw_url：
  /// `<rawBaseUrl><path>?sign=<sign>`
  ///
  /// 当 [rawBaseUrl] 为空时，回退到 Alist 标准下载链接：
  /// `<currentServer>/d/<path>?sign=<sign>`
  /// `/d/` 会 302 重定向到实际 raw_url，播放器需支持跟随重定向。
  ///
  /// - [sign] 非空时附加 `?sign=` 参数（受保护文件需要）
  /// - [path] 以 `/` 开头（Alist 路径规范）
  String _buildDownloadUrl(String path, String sign) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final rawBase = rawBaseUrl;
    if (rawBase != null && rawBase.isNotEmpty) {
      final encodedPath = _encodePathSegments(normalizedPath);
      if (sign.isEmpty) {
        return '$rawBase$encodedPath';
      }
      return '$rawBase$encodedPath?sign=$sign';
    }

    final base = _currentServer.baseUrl;
    if (sign.isEmpty) {
      return '$base/d$normalizedPath';
    }
    return '$base/d$normalizedPath?sign=$sign';
  }

  /// 对路径中的每一段做 URL 编码，保留 `/` 作为分隔符。
  ///
  /// Alist 路径可能包含中文或特殊字符（如空格、`[`、`]`），直接拼接会
  /// 导致播放器/下载器请求失败。此辅助函数仅编码路径段，不编码 `/`。
  String _encodePathSegments(String path) {
    return path
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
  }
}
