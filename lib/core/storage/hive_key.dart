class StorageKeys {
  StorageKeys._();

  // ==================== Settings Box Keys ====================
  static const String currentHost = 'current_host';
  static const String recommendUuid = 'recommend_uuid';
  static const String searchHistory = 'search_history';

  // ==================== Auth Box Keys ====================
  static const String currentUser = 'current_user';

  // ==================== Player Box Keys ====================
  static const String playerLastState = 'last_state';

  // ==================== Scanner Box Keys & Prefixes ====================
  // 扫描结果的前缀，用于动态拼接 key: path_{mode} 或 item_{mode}
  static const String scanPrefixPath = 'path_';
  static const String scanPrefixItem = 'item_';

  // ==================== Option Keys (Settings Box) ====================
  static const String tagOption = 'tag_option';
  static const String vasOption = 'vas_option';
  static const String circleOption = 'circle_option';
  static const String autoUpdate = 'auto_update';
  static const String quickMarkTargetPlaylist = 'quick_mark_target_playlist';
  static const String nsfwKey = 'nsfw_enabled'; // 定义 Key

  // ==================== Internal Wrapper Keys ====================
  // 用于 _saveOption 包装数据和过期时间
  static const String wrapperValue = 'val';
  static const String wrapperExpiry = 'exp';


}