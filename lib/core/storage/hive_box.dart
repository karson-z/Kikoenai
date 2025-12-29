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

  static const List<String> values = [
    settings,
    logs,
    history,
    playerState
  ];
}
