import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

// 引入你的项目路径
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/auth/data/model/auth_response.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/widgets/player/state/player_state.dart';
import 'package:kikoenai/core/model/app_media_item.dart';
import '../file/file_scanner_service.dart';
// 引入新定义的 Key 常量类
import '../../storage/hive_key.dart';
import '../../../features/playlist/data/model/playlist.dart';

class CacheService {
  // 单例模式
  CacheService._();
  static final CacheService instance = CacheService._();

  static const int _maxHistory = 200;

  // ------------------------- 快速添加到播放列表 -------------------------

  /// 保存目标列表
  Future<void> saveQuickMarkTargetPlaylist(Playlist playlist) async {
    // 假设 Playlist 使用 Freezed/JsonSerializable 生成了 toJson 方法
    await AppStorage.settingsBox.put(
        StorageKeys.quickMarkTargetPlaylist,
        playlist.toJson()
    );
  }

  /// 获取目标列表
  Playlist? getQuickMarkTargetPlaylist() {
    final data = AppStorage.settingsBox.get(StorageKeys.quickMarkTargetPlaylist);

    if (data != null && data is Map) {
      try {
        final jsonMap = Map<String, dynamic>.from(data);
        return Playlist.fromJson(jsonMap);
      } catch (e) {
        debugPrint('Error parsing QuickMarkTargetPlaylist: $e');
        clearQuickMarkTargetPlaylist();
      }
    }
    return null;
  }

  /// 清除目标歌单
  Future<void> clearQuickMarkTargetPlaylist() async {
    await AppStorage.settingsBox.delete(StorageKeys.quickMarkTargetPlaylist);
  }
  // ==================== 1. 基础配置与 UUID ====================

  Future<void> saveCurrentHost(String host) async {
    await AppStorage.settingsBox.put(StorageKeys.currentHost, host);
  }

  String? getCurrentHost() {
    return AppStorage.settingsBox.get(StorageKeys.currentHost);
  }

  Future<String> getOrGenerateRecommendUuid() async {
    String? uuid = AppStorage.settingsBox.get(StorageKeys.recommendUuid);
    if (uuid != null && uuid.isNotEmpty) return uuid;

    final newUuid = const Uuid().v4();
    await AppStorage.settingsBox.put(StorageKeys.recommendUuid, newUuid);
    return newUuid;
  }

  // ==================== 2. Auth (登录态) ====================

  Future<void> saveAuthSession(AuthResponse auth) async {
    // [Refactored] 使用常量 key
    await AppStorage.authBox.put(StorageKeys.currentUser, auth);
  }

  AuthResponse? getAuthSession() {
    // [Refactored] 使用常量 key
    return AppStorage.authBox.get(StorageKeys.currentUser);
  }

  Future<void> clearAuthSession() async {
    // [Refactored] 使用常量 key
    await AppStorage.authBox.delete(StorageKeys.currentUser);
  }

  // ==================== 3. 搜索历史 ====================

  List<String> getSearchHistory() {
    final list = AppStorage.settingsBox.get(StorageKeys.searchHistory);
    return (list as List?)?.cast<String>() ?? [];
  }

  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    List<String> history = getSearchHistory();
    history.remove(keyword);
    history.insert(0, keyword);
    if (history.length > 20) history = history.sublist(0, 20);

    await AppStorage.settingsBox.put(StorageKeys.searchHistory, history);
  }

  Future<void> removeSearchHistory(String keyword) async {
    List<String> history = getSearchHistory();
    history.remove(keyword);
    await AppStorage.settingsBox.put(StorageKeys.searchHistory, history);
  }

  Future<void> clearSearchHistory() =>
      AppStorage.settingsBox.delete(StorageKeys.searchHistory);

  // ==================== 4. 播放器状态 ====================

  Future<void> savePlayerState(AppPlayerState state) async {
    // [Refactored] 使用常量 key
    await AppStorage.playerBox.put(StorageKeys.playerLastState, state);
  }

  AppPlayerState? getPlayerState() {
    // [Refactored] 使用常量 key
    return AppStorage.playerBox.get(StorageKeys.playerLastState);
  }

  // ==================== 5. 播放历史 ====================

  /// 获取历史列表 (按时间倒序)
  List<HistoryEntry> getHistoryList() {
    final list = AppStorage.historyBox.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// 添加历史记录
  Future<void> addToHistory(HistoryEntry entry) async {
    // HistoryBox 的 Key 是动态的 (WorkId)，所以这里保持原样
    await AppStorage.historyBox.put(entry.work.id, entry);

    if (AppStorage.historyBox.length > _maxHistory) {
      _trimHistory();
    }
  }

  Future<void> _trimHistory() async {
    final list = getHistoryList();
    if (list.length <= _maxHistory) return;

    final keysToDelete = list
        .sublist(_maxHistory)
        .map((e) => e.work.id);

    await AppStorage.historyBox.deleteAll(keysToDelete);
  }

  Future<void> clearHistory() async {
    await AppStorage.historyBox.clear();
  }

  // ==================== 6. 扫描与缓存 (Scan) ====================

  /// [Refactored] 动态 Key 生成逻辑现在使用常量前缀
  String _getScanKey(ScanMode mode, bool isPath) {
    final prefix = isPath ? StorageKeys.scanPrefixPath : StorageKeys.scanPrefixItem;
    return '${prefix}_${mode.name}';
  }

  Future<void> saveScanRootPaths(List<String> paths, {required ScanMode mode}) async {
    await AppStorage.scannerBox.put(_getScanKey(mode, true), paths);
  }

  List<String> getScanRootPaths({required ScanMode mode}) {
    final list = AppStorage.scannerBox.get(_getScanKey(mode, true));
    return (list as List?)?.cast<String>() ?? [];
  }

  Future<void> saveScanResults(List<AppMediaItem> items, {required ScanMode mode}) async {
    final jsonList = items.map((e) => e.toJson()).toList();
    await AppStorage.scannerBox.put(_getScanKey(mode, false), jsonList);
  }

  List<AppMediaItem> getCachedScanResults({required ScanMode mode}) {
    final data = AppStorage.scannerBox.get(_getScanKey(mode, false));
    if (data is List) {
      return data.map((e) {
        if (e is AppMediaItem) return e;
        return AppMediaItem.fromJson(Map<String, dynamic>.from(e));
      }).toList();
    }
    return [];
  }

  Future<void> clearScanResults({required ScanMode mode}) async {
    await AppStorage.scannerBox.delete(_getScanKey(mode, false));
  }

  // ==================== 7. 配置选项 (带过期逻辑) ====================

  // [Refactored] 内部包装的 Key ('val', 'exp') 也提取为常量
  Future<void> _saveOption(String key, dynamic value) async {
    final data = {
      StorageKeys.wrapperValue: value,
      StorageKeys.wrapperExpiry: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch
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

  Future<void> saveTagsOption(List<Map<String, dynamic>> val) => _saveOption(StorageKeys.tagOption, val);
  Future<List<Map<String, dynamic>>?> getTagsOption() async => _getOption(StorageKeys.tagOption);

  Future<void> saveVasOption(List<Map<String, dynamic>> val) => _saveOption(StorageKeys.vasOption, val);
  Future<List<Map<String, dynamic>>?> getVasOption() async => _getOption(StorageKeys.vasOption);

  Future<void> saveCirclesOption(List<Map<String, dynamic>> val) => _saveOption(StorageKeys.circleOption, val);
  Future<List<Map<String, dynamic>>?> getCirclesOption() async => _getOption(StorageKeys.circleOption);

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