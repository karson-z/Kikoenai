/// Hive box name constants
class BoxNames {
  /// 用户信息及登录Token数据
  static const String auth = 'auth';
  /// 缓存数据
  static const String settings = 'settings';
  /// 扫描路径
  static const String scanner = 'scanner';
  /// 日志数据
  static const String logs = 'logs';
  /// 观看记录
  static const String history = 'history';
  /// 播放状态
  static const String playerState = 'player_state';
  /// 抓取的作品元数据
  static const String scraper = 'scraper_work';
  /// 抓取的作品元数据
  static const String lyricsMatch = 'lyrics_match';
  /// 筛选盒子
  static const String globalFilterTags = 'global_filter_tags';
  /// 扫描目标
  static const String scanTarget = 'scan_target';

  static const List<String> values = [
    settings,
    logs,
    history,
    playerState,
    auth,
    scanner,
    scraper,
    lyricsMatch,
    globalFilterTags
  ];
}
