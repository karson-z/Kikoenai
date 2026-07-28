import 'package:kikoenai_core/kikoenai_core.dart';

import 'listen_event_type.dart';
import 'server_health.dart';
import 'server_info.dart';
import 'site_feature.dart';

/// 站点 API 统一接口。
///
/// 所有站点实现本类，通过 [supportedFeatures] 显式声明支持的功能点，
/// 调用方在调用具体方法前应使用 [supports] 判断。
///
/// 不支持的方法默认抛出 [UnsupportedError]，子类按需 override 即可，
/// 无需为每个不支持的功能写空实现，也无需引入大量 capability 接口。
///
/// ### 设计要点
///
/// - **方法聚合**：所有站点方法集中在 [SiteApi]，避免 capability 接口爆炸
/// - **细粒度声明**：通过 [SiteFeature] 枚举声明具体支持点
/// - **编译期 + 运行时双层**：站点 `extends SiteApi` 即获得所有方法签名，
///   调用方运行时用 [supports] 判断子功能
///
/// ### 示例
///
/// ```dart
/// class MySiteApi extends SiteApi {
///   @override
///   Set<SiteFeature> get supportedFeatures => const {
///     SiteFeature.search,
///     SiteFeature.detail,
///   };
///
///   @override
///   Future<PagedResult<Work>> searchWorks(SearchWorksRequest req) async {
///     // ...
///   }
///
///   @override
///   Future<Work> getWorkDetail(String workId) async {
///     // ...
///   }
/// }
/// ```
abstract class SiteApi {
  const SiteApi();

  /// 当前站点支持的功能集合。
  ///
  /// 子类应返回一个常量集合，仅包含其真正实现的功能点。
  /// 调用方在调用方法前应通过 [supports] 判断。
  Set<SiteFeature> get supportedFeatures;

  /// 判断是否支持指定功能
  bool supports(SiteFeature feature) => supportedFeatures.contains(feature);

  // ─── 检索类 ──────────────────────────────────────────

  /// 搜索作品（按关键字 / 排序 / 字幕过滤等）
  Future<PagedResult<Work>> searchWorks(SearchWorksRequest req) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.search}');

  /// 获取热门作品
  Future<PagedResult<Work>> getPopularWorks(SearchWorksRequest req) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.popular}');

  /// 获取个性化推荐作品
  Future<PagedResult<Work>> getRecommendedWorks(SearchWorksRequest req) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.recommend}');

  /// 获取社团列表
  Future<List<Circle>> getCircles() =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.circles}');

  /// 获取标签列表
  Future<List<Tag>> getTags() =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.tags}');

  /// 获取声优列表
  Future<List<VA>> getVas() =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.vas}');

  // ─── 详情与音轨 ──────────────────────────────────────

  /// 获取作品详细信息
  Future<Work> getWorkDetail(String workId) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.detail}');

  /// 获取作品音轨列表（树形结构，文件夹节点通过 [FileNode.children] 携带子节点）
  Future<List<FileNode>> getWorkTracks(String workId) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.tracks}');

  // ─── 收藏 / 播放列表 ────────────────────────────────

  /// 获取播放列表分页
  Future<PagedResult<Playlist>> fetchPlaylists({
    required int page,
    int pageSize = 20,
    String filterBy = 'all',
  }) => throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.playlists}');

  /// 获取播放列表内的作品分页
  Future<PagedResult<Work>> fetchPlaylistWorks({
    required String playlistId,
    required int page,
    int pageSize = 12,
  }) => throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.playlistWorks}');

  /// 按关键字搜索播放列表内的作品
  Future<PagedResult<Work>> fetchPlaylistWorksByKeyword(
    PlaylistWorksRequest request,
  ) => throw UnsupportedError(
    '$runtimeType 不支持 ${SiteFeature.playlistWorksByKeyword}',
  );

  /// 获取默认收藏目标播放列表
  Future<Playlist> fetchDefaultMarkTargetPlaylist() => throw UnsupportedError(
    '$runtimeType 不支持 ${SiteFeature.defaultMarkTargetPlaylist}',
  );

  /// 添加作品到播放列表
  Future<void> addWorksToPlaylist({
    required String playlistId,
    required List<String> workIds,
  }) => throw UnsupportedError(
    '$runtimeType 不支持 ${SiteFeature.addWorksToPlaylist}',
  );

  /// 从播放列表移除作品
  Future<void> removeWorksFromPlaylist({
    required String playlistId,
    required List<String> workIds,
  }) => throw UnsupportedError(
    '$runtimeType 不支持 ${SiteFeature.removeWorksFromPlaylist}',
  );

  // ─── 评论 ──────────────────────────────────────────

  /// 获取作品评论 / 评价列表
  Future<PagedResult<Work>> fetchReviews(ReviewQueryParams params) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.reviews}');

  /// 提交评价（评分 / 评论 / 进度），返回服务端响应
  Future<Map<String, dynamic>> submitReview({
    required String workId,
    required UserWorkStatus workStatus,
  }) => throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.submitReview}');

  // ─── 认证 ──────────────────────────────────────────

  /// 登录
  Future<AuthResponse> login(LoginParams loginParams) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.login}');

  /// 注册
  Future<AuthResponse> register(RegisterRequestModel reg) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.register}');

  // ─── 埋点 ──────────────────────────────────────────

  /// 上报播放反馈埋点（如开始播放 / 播放满 5 分钟）。
  ///
  /// [workId] 当前播放的作品 ID
  /// [recommendUuid] 推荐算法 UUID
  /// [type] 事件类型
  Future<void> submitPlaybackFeedback({
    required String workId,
    required String recommendUuid,
    required ListenEventType type,
  }) => throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.feedback}');

  // ─── 服务器管理 ──────────────────────────────────────

  /// 当前使用的服务器。
  ///
  /// 仅当站点声明 [SiteFeature.serverSwitch] 时有意义。
  /// 若站点声明了 [SiteInfo.servers] 但未声明 [SiteFeature.serverSwitch]，
  /// 业务层可回退使用 [SiteInfo.defaultServer]。
  ServerInfo get currentServer =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.serverSwitch}');

  /// 切换到指定服务器
  Future<void> switchServer(ServerInfo server) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.serverSwitch}');

  /// 检查指定服务器的健康状态
  Future<ServerHealth> checkHealth(ServerInfo server) =>
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.healthCheck}');

  /// 批量检查多个服务器（并发执行）
  Future<List<ServerHealth>> checkAllHealth(List<ServerInfo> servers) async {
    if (!supports(SiteFeature.healthCheck)) {
      throw UnsupportedError('$runtimeType 不支持 ${SiteFeature.healthCheck}');
    }
    return Future.wait(servers.map(checkHealth));
  }
}
