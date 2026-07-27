/// 站点功能点枚举。
///
/// 用于 [SiteApi.supportedFeatures] 声明当前站点支持的具体功能。
/// 调用方在调用方法前应通过 [SiteApi.supports] 判断功能是否可用，
/// 避免触发方法默认抛出的 [UnsupportedError]。
enum SiteFeature {
  // ─── 检索类 ──────────────────────────────────────────
  /// 关键字搜索作品（必选基础能力）
  search,

  /// 热门作品
  popular,

  /// 个性化推荐
  recommend,

  /// 社团列表
  circles,

  /// 标签列表
  tags,

  /// 声优列表
  vas,

  // ─── 详情与音轨 ──────────────────────────────────────
  /// 作品详情
  detail,

  /// 作品音轨树
  tracks,

  // ─── 收藏 / 播放列表 ────────────────────────────────
  /// 获取播放列表分页
  playlists,

  /// 获取播放列表内作品分页
  playlistWorks,

  /// 按关键字搜索播放列表内作品
  playlistWorksByKeyword,

  /// 获取默认收藏目标播放列表
  defaultMarkTargetPlaylist,

  /// 添加作品到播放列表
  addWorksToPlaylist,

  /// 从播放列表移除作品
  removeWorksFromPlaylist,

  // ─── 评论 ──────────────────────────────────────────
  /// 获取作品评论列表
  reviews,

  /// 提交评价（评分 / 评论 / 进度）
  submitReview,

  // ─── 认证 ──────────────────────────────────────────
  /// 登录
  login,

  /// 注册
  register,

  // ─── 服务器管理 ──────────────────────────────────────
  /// 服务器切换
  serverSwitch,

  /// 健康检查
  healthCheck,
}
