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

// 可以继续增加其他 key
// static const String anotherKey = 'anotherKey';
}
