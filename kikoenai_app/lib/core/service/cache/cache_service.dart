import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

// 引入你的项目路径
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/core/utils/other.dart';
import 'package:kikoenai_core/core/model/user/auth_response.dart';
import 'package:kikoenai_core/core/model/player/player_state.dart';
import 'package:kikoenai_core/core/model/playlist/playlist.dart';
import 'package:kikoenai_core/core/model/local_media/scan_mode.dart';

class CacheService {
  // 单例模式
  CacheService._();
  static final CacheService instance = CacheService._();

  static const int _maxHistory = 200;
  static const String legacySiteId = 'asmr.one';

  String _siteKey(String key, String siteId) =>
      StorageKeys.forSite(key, siteId);

  String? getActiveSiteId() {
    return AppStorage.settingsBox.get(StorageKeys.activeSiteId) as String?;
  }

  Future<void> saveActiveSiteId(String siteId) async {
    await AppStorage.settingsBox.put(StorageKeys.activeSiteId, siteId);
  }

  /// Copies pre-multi-site values into ASMR.ONE's namespace without deleting
  /// the old keys. This makes rollback and older app versions non-destructive.
  Future<void> migrateLegacySiteData({String siteId = legacySiteId}) async {
    final settingsKeys = <String>[
      StorageKeys.quickMarkTargetPlaylist,
      StorageKeys.currentHost,
      StorageKeys.recommendUuid,
      StorageKeys.searchHistory,
      StorageKeys.tagOption,
      StorageKeys.vasOption,
      StorageKeys.circleOption,
    ];
    for (final legacyKey in settingsKeys) {
      final scopedKey = _siteKey(legacyKey, siteId);
      if (!AppStorage.settingsBox.containsKey(scopedKey) &&
          AppStorage.settingsBox.containsKey(legacyKey)) {
        await AppStorage.settingsBox.put(
          scopedKey,
          AppStorage.settingsBox.get(legacyKey),
        );
      }
    }

    final scopedAuthKey = _siteKey(StorageKeys.currentUser, siteId);
    if (!AppStorage.authBox.containsKey(scopedAuthKey) &&
        AppStorage.authBox.containsKey(StorageKeys.currentUser)) {
      await AppStorage.authBox.put(
        scopedAuthKey,
        AppStorage.authBox.get(StorageKeys.currentUser)!,
      );
    }
  }

  // ------------------------- 快速添加到播放列表 -------------------------

  /// 保存目标列表
  Future<void> saveQuickMarkTargetPlaylist(
    Playlist playlist, {
    String siteId = legacySiteId,
  }) async {
    // 假设 Playlist 使用 Freezed/JsonSerializable 生成�?toJson 方法
    await AppStorage.settingsBox.put(
      _siteKey(StorageKeys.quickMarkTargetPlaylist, siteId),
      playlist.toJson(),
    );
  }

  /// 获取目标列表
  Playlist? getQuickMarkTargetPlaylist({String siteId = legacySiteId}) {
    final data = AppStorage.settingsBox.get(
      _siteKey(StorageKeys.quickMarkTargetPlaylist, siteId),
    );

    if (data != null && data is Map) {
      try {
        final jsonMap = Map<String, dynamic>.from(data);
        return Playlist.fromJson(jsonMap);
      } catch (e) {
        debugPrint('Error parsing QuickMarkTargetPlaylist: $e');
        clearQuickMarkTargetPlaylist(siteId: siteId);
      }
    }
    return null;
  }

  /// 清除目标歌单
  Future<void> clearQuickMarkTargetPlaylist({
    String siteId = legacySiteId,
  }) async {
    await AppStorage.settingsBox.delete(
      _siteKey(StorageKeys.quickMarkTargetPlaylist, siteId),
    );
  }
  // ==================== 1. 基础配置�?UUID ====================

  Future<void> saveCurrentHost(
    String host, {
    String siteId = legacySiteId,
  }) async {
    await AppStorage.settingsBox.put(
      _siteKey(StorageKeys.currentHost, siteId),
      host,
    );
  }

  String? getCurrentHost({String siteId = legacySiteId}) {
    return AppStorage.settingsBox.get(_siteKey(StorageKeys.currentHost, siteId))
        as String?;
  }

  Future<String> getOrGenerateRecommendUuid({
    String siteId = legacySiteId,
  }) async {
    final key = _siteKey(StorageKeys.recommendUuid, siteId);
    String? uuid = AppStorage.settingsBox.get(key) as String?;
    if (uuid != null && uuid.isNotEmpty) return uuid;

    final newUuid = const Uuid().v4();
    await AppStorage.settingsBox.put(key, newUuid);
    return newUuid;
  }

  // ==================== 2. Auth (登录�? ====================

  Future<void> saveAuthSession(
    AuthResponse auth, {
    String siteId = legacySiteId,
  }) async {
    // [Refactored] 使用常量 key
    await AppStorage.authBox.put(
      _siteKey(StorageKeys.currentUser, siteId),
      auth,
    );
  }

  AuthResponse? getAuthSession({String siteId = legacySiteId}) {
    // [Refactored] 使用常量 key
    return AppStorage.authBox.get(_siteKey(StorageKeys.currentUser, siteId));
  }

  Future<void> clearAuthSession({String siteId = legacySiteId}) async {
    // [Refactored] 使用常量 key
    await AppStorage.authBox.delete(_siteKey(StorageKeys.currentUser, siteId));
  }

  // ==================== 3. 搜索历史 ====================

  List<String> getSearchHistory({String siteId = legacySiteId}) {
    final list = AppStorage.settingsBox.get(
      _siteKey(StorageKeys.searchHistory, siteId),
    );
    return (list as List?)?.cast<String>() ?? [];
  }

  Future<void> addSearchHistory(
    String keyword, {
    String siteId = legacySiteId,
  }) async {
    if (keyword.trim().isEmpty) return;
    List<String> history = getSearchHistory(siteId: siteId);
    history.remove(keyword);
    history.insert(0, keyword);
    if (history.length > 20) history = history.sublist(0, 20);

    await AppStorage.settingsBox.put(
      _siteKey(StorageKeys.searchHistory, siteId),
      history,
    );
  }

  Future<void> removeSearchHistory(
    String keyword, {
    String siteId = legacySiteId,
  }) async {
    List<String> history = getSearchHistory(siteId: siteId);
    history.remove(keyword);
    await AppStorage.settingsBox.put(
      _siteKey(StorageKeys.searchHistory, siteId),
      history,
    );
  }

  Future<void> clearSearchHistory({String siteId = legacySiteId}) => AppStorage
      .settingsBox
      .delete(_siteKey(StorageKeys.searchHistory, siteId));

  // ==================== 4. 播放器状�?====================

  Future<void> savePlayerState(AppPlayerState state) async {
    // [Refactored] 使用常量 key
    await AppStorage.playerBox.put(StorageKeys.playerLastState, state);
  }

  AppPlayerState? getPlayerState() {
    // [Refactored] 使用常量 key
    return AppStorage.playerBox.get(StorageKeys.playerLastState);
  }

  // ==================== 获取用户选择的扫描路�?====================

  /// [Refactored] 动�?Key 生成逻辑现在使用常量前缀
  String _getScanKey(ScanMode mode, bool isPath) {
    final prefix = isPath
        ? StorageKeys.scanPrefixPath
        : StorageKeys.scanPrefixItem;
    return '${prefix}_${mode.name}';
  }

  Future<void> saveScanRootPaths(
    List<String> paths, {
    required ScanMode mode,
  }) async {
    await AppStorage.settingsBox.put(_getScanKey(mode, true), paths);
  }

  List<String> getScanRootPaths({
    List<ScanMode> allModes = ScanMode.values,
    ScanMode? mode,
  }) {
    // 如果传了具体 mode，直接返�?
    if (mode != null) {
      final list = AppStorage.settingsBox.get(_getScanKey(mode, true));
      return (list as List?)?.cast<String>() ?? [];
    }
    // 否则，基�?allModes 范围进行合并
    final allPaths = <String>{};
    for (var m in allModes) {
      final list = AppStorage.scannerBox.get(_getScanKey(m, true));
      if (list != null) {
        allPaths.addAll((list as List).cast<String>());
      }
    }
    return allPaths.toList();
  }

  // ==================== 7. 配置选项 (带过期逻辑) ====================

  // [Refactored] 内部包装�?Key ('val', 'exp') 也提取为常量
  Future<void> _saveOption(String key, dynamic value) async {
    final data = {
      StorageKeys.wrapperValue: value,
      StorageKeys.wrapperExpiry: DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch,
    };
    await AppStorage.settingsBox.put(key, data);
  }

  List<Map<String, dynamic>>? _getOption(String key) {
    final data = AppStorage.settingsBox.get(key);
    if (data is Map) {
      // [Refactored] 读取常量 Key
      final exp = data[StorageKeys.wrapperExpiry] as int? ?? 0;

      if (DateTime.now().millisecondsSinceEpoch < exp) {
        final val = data[StorageKeys.wrapperValue];
        if (val is List) {
          return val.map((e) => OtherUtil.deepConvert(e as Map)).toList();
        }
      } else {
        AppStorage.settingsBox.delete(key);
      }
    }
    return null;
  }

  Future<void> saveTagsOption(
    List<Map<String, dynamic>> val, {
    String siteId = legacySiteId,
  }) => _saveOption(_siteKey(StorageKeys.tagOption, siteId), val);
  Future<List<Map<String, dynamic>>?> getTagsOption({
    String siteId = legacySiteId,
  }) async => _getOption(_siteKey(StorageKeys.tagOption, siteId));

  Future<void> saveVasOption(
    List<Map<String, dynamic>> val, {
    String siteId = legacySiteId,
  }) => _saveOption(_siteKey(StorageKeys.vasOption, siteId), val);
  Future<List<Map<String, dynamic>>?> getVasOption({
    String siteId = legacySiteId,
  }) async => _getOption(_siteKey(StorageKeys.vasOption, siteId));

  Future<void> saveCirclesOption(
    List<Map<String, dynamic>> val, {
    String siteId = legacySiteId,
  }) => _saveOption(_siteKey(StorageKeys.circleOption, siteId), val);
  Future<List<Map<String, dynamic>>?> getCirclesOption({
    String siteId = legacySiteId,
  }) async => _getOption(_siteKey(StorageKeys.circleOption, siteId));

  // ==================== 8. 工具方法 ====================

  Future<void> clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
      debugPrint("Box [$boxName] cleared successfully.");
    } else {
      debugPrint("Box [$boxName] is not open, trying to delete file...");
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (e) {
        debugPrint("Failed to clear box $boxName: $e");
      }
    }
  }

  Future<int> getBoxFileSize(String boxName) async {
    return AppStorage.getBoxSize(boxName);
  }
}
