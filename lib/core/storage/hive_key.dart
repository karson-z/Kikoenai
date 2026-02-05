class StorageKeys {
  StorageKeys._();

  // ==================== Settings Box Keys (通用设置) ====================

  /// 当前选中的服务器配置/地址
  /// 用于多服务器切换场景
  static const String currentHost = 'current_host';

  /// 推荐系统的会话 UUID
  /// 用于标记推荐流的上下文或用户指纹
  static const String recommendUuid = 'recommend_uuid';

  /// 用户搜索历史列表
  /// 存储 List<String>
  static const String searchHistory = 'search_history';

  // ==================== Auth Box Keys (认证相关) ====================

  /// 当前登录的用户信息
  /// 通常存储 User 对象的序列化 JSON
  static const String currentUser = 'current_user';

  // ==================== Player Box Keys (播放器状态) ====================

  /// 播放器最后的状态
  /// 用于应用重启后恢复播放进度、当前歌曲、播放列表等
  static const String playerLastState = 'last_state';

  // ==================== Scanner Box Keys & Prefixes (扫描相关) ====================

  /// 扫描路径的前缀 Key
  /// 用法示例: "${StorageKeys.scanPrefixPath}$mode"
  static const String scanPrefixPath = 'path_';

  /// 扫描结果条目的前缀 Key
  /// 用法示例: "${StorageKeys.scanPrefixItem}$itemId"
  static const String scanPrefixItem = 'item_';

  // ==================== Option Keys (Settings Box - 用户偏好) ====================

  /// 标签(Tag)筛选或显示选项
  static const String tagOption = 'tag_option';

  /// 声优(Voice Actor)筛选或显示选项
  static const String vasOption = 'vas_option';

  /// 社团(Circle/Group)筛选或显示选项
  static const String circleOption = 'circle_option';

  /// 是否开启自动更新检查
  /// 类型: bool
  static const String autoUpdate = 'auto_update';

  /// "快速收藏"的目标播放列表 ID
  /// 当用户点击快速收藏按钮时，音频将被添加到的默认列表
  static const String quickMarkTargetPlaylist = 'quick_mark_target_playlist';

  /// 是否启用成人模式 (NSFW)
  /// 类型: bool
  static const String nsfwKey = 'nsfw_enabled';

  /// 文件下载保存的本地目录路径
  static const String fileDownloadKey = 'file_download_path';

  /// 字幕样式配置对象
  /// 存储 LyricConfigModel，包含字体大小、行间距等细分设置
  static const String lyricsStyleConfig = 'lyrics_style_config';

  // ==================== Internal Wrapper Keys (内部缓存包装) ====================

  /// 缓存包装器 - 实际数据字段 Key
  /// 用于 _saveOption 等方法中包装带过期时间的数据
  static const String wrapperValue = 'val';

  /// 缓存包装器 - 过期时间字段 Key
  /// 存储时间戳
  static const String wrapperExpiry = 'exp';
}