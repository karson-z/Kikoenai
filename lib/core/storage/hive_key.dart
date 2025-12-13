/// 全局存储 key 常量
class StorageKeys {
  /// User Box Keys
  static const String currentUser = 'currentUser'; // Hive 保存的用户 JSON
  static const String token = 'token';             // SharedPreferences 保存的 token

  /// Settings Box Keys
  static const String theme = 'theme';             // App 主题
  static const String language = 'language';       // App 语言

  /// Cache Box Keys
  static const String lastSyncTime = 'lastSyncTime'; // 上次同步时间
  static const String tempData = 'tempData';         // 临时缓存数据

  /// Logs Box Keys
  static const String lastError = 'lastError';       // 最近一次错误日志

  static const String pathSubtitle = 'path_subtitle';
  static const String pathVideo = 'path_video';
  static const String pathAudio = 'path_audio';
  static const String pathImage = 'path_image';
  static const String pathArchive = 'path_archive';

}
/// 缓存 key 常量
class CacheKeys {
  static const String playlist = 'playlist';
  static const String currentTrack = 'currentTrack';
  static const String currentIndex = 'currentIndex';
  static const String history = 'history';
  static const String tagOption = 'tag';
  static const String vasOption = 'vas';
  static const String circleOption = 'circle';

  static const String playerState = 'playerstate';
}