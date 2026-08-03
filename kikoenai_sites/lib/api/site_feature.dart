/// 站点功能点枚举。
///
/// 用于 [SiteApi.supportedFeatures] 声明当前站点支持的具体功能。
/// 调用方在调用方法前应通过 [SiteApi.supports] 判断功能是否可用，
/// 避免触发方法默认抛出的 [UnsupportedError]。
enum SiteFeature {
  // ─── 检索类 ──────────────────────────────────────────
  /// 关键字搜索作品
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

  // ─── 埋点 ──────────────────────────────────────────
  /// 播放反馈埋点（如开始播放 / 播放满 5 分钟）
  feedback,

  // ─── 服务器管理 ──────────────────────────────────────────
  /// 服务器切换
  serverSwitch,

  /// 健康检查
  healthCheck,

  // ─── 文件系统（Alist 风格站点）──────────────────────
  /// 按路径浏览文件系统目录（Alist 风格 `/api/fs/list`）
  ///
  /// 适用于以文件系统目录树组织内容的站点（如 asmr.pw），
  /// 与按 workId 检索作品的数据库型站点（如 asmr.one）相对。
  fileSystemBrowse,

  /// 获取站点 / 目录说明（readme，Markdown）
  ///
  /// Alist 站点的 `/api/fs/list` 响应会携带 `readme` 字段，
  /// 包含站点公告、分类说明、解压密码等 markdown 文本。
  siteReadme,

  /// 按关键字搜索文件系统（Alist 风格 `/api/fs/search`）
  ///
  /// 与 [fileSystemBrowse] 的按路径浏览不同，搜索会跨目录递归匹配
  /// 文件 / 目录名。常用于按 RJ 号定位作品目录。
  fileSystemSearch,
}
