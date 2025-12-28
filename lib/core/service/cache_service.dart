import 'dart:convert';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/user/data/models/user.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/data/model/auth_response.dart';
import '../model/app_media_item.dart';
import '../model/history_entry.dart';
import '../storage/hive_box.dart';
import '../storage/hive_key.dart';
import '../storage/hive_storage.dart';
import '../widgets/player/state/player_state.dart';
import 'file_scanner_service.dart';

class CacheService {
  static const int _maxHistory = 200;

  final HiveStorage _storage;

  final Duration _defaultExpire = const Duration(days: 1); // 默认缓存1天
  // 私有构造函数
  CacheService._internal(this._storage);

  // 单例实例
  static CacheService? _instance;

  /// 初始化单例
  static CacheService initialize(HiveStorage storage) {
    _instance ??= CacheService._internal(storage);
    return _instance!;
  }

  /// 获取单例
  static CacheService get instance {
    if (_instance == null) {
      throw Exception('CacheService not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  Future<void> _saveWithExpire(String key, dynamic value, [Duration? expire]) async {
    final expireAt = DateTime.now().add(expire ?? _defaultExpire).millisecondsSinceEpoch;
    final data = {'value': value, 'expireAt': expireAt};
    await _storage.put(BoxNames.cache, key, data);
  }

  Future<dynamic> _getWithExpire(String key) async {
    final stored = await _storage.get(BoxNames.cache, key);
    if (stored is Map && stored.containsKey('value') && stored.containsKey('expireAt')) {
      final expireAt = stored['expireAt'];
      if (expireAt is int && DateTime.now().millisecondsSinceEpoch < expireAt) {
        return stored['value'];
      } else {
        // 已过期，删除缓存
        await _storage.delete(BoxNames.cache, key);
      }
    }
    return null;
  }
  // ------------------------------- 当前host --------------------------
  Future<void> saveCurrentHost(String host) async {
    await _storage.put(BoxNames.cache, CacheKeys.currentHost, host);
  }
  Future<String?> getCurrentHost() async {
    return await _storage.get(BoxNames.cache, CacheKeys.currentHost);
  }

  // ------------------------------- 账户信息 ---------------------------
  Future<void> saveAuthSession(AuthResponse authResponse) async {
    final jsonString = jsonEncode(authResponse.toJson());

    await _storage.put(
      BoxNames.cache,
      StorageKeys.currentUser,
      jsonString,
    );
  }

  Future<AuthResponse?> getAuthSession() async {
    try {
      final jsonString = await _storage.get(BoxNames.cache, StorageKeys.currentUser);

      if (jsonString != null && jsonString is String && jsonString.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonString);

        return AuthResponse.fromJson(map);
      }
    } catch (e) {
      print('Error parsing auth session: $e');
      await _storage.delete(BoxNames.cache, StorageKeys.currentUser);
    }
    return null;
  }
  /// 清除会话信息 (用于退出登录)
  Future<void> clearAuthSession() async {
    await _storage.delete(BoxNames.cache, StorageKeys.currentUser);
  }
  // 用户第一次登录时生成的uuid（不管是否登录都会生成）,用于个性化推荐
  Future<String?> getRecommendUuid() async {
    // 显式转换为 String? 比较安全，取决于你的 _storage 库 (如 Hive) 返回的是 dynamic 还是什么
    return await _storage.get(BoxNames.cache, CacheKeys.recommendUuid) as String?;
  }

  Future<String> getOrGenerateRecommendUuid() async {
    // 获取可能为 null 的 uuid
    String? uuid = await getRecommendUuid();

    // 2. 严谨的判空逻辑：既要不为 null，也要不为空字符串
    if (uuid != null && uuid.isNotEmpty) {
      return uuid;
    }

    // 生成新的 UUID
    final newUuid = const Uuid().v4();

    // 保存并返回
    await _storage.put(BoxNames.cache, CacheKeys.recommendUuid, newUuid);
    return newUuid;
  }

  //-------------------------------- 搜索关键字 -----------------------------
  /// 获取搜索历史列表
  Future<List<String>> getSearchHistory() async {
    // 假设 key 为 'search_history'
    final list = await _storage.get(BoxNames.cache, CacheKeys.searchHistory);
    if (list is List) {
      return list.cast<String>();
    }
    return [];
  }

  /// 添加搜索历史 (自动去重、置顶、限制数量)
  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    List<String> history = await getSearchHistory();

    // 如果已存在，先移除（为了移到最前面）
    history.remove(keyword);

    // 插入到头部
    history.insert(0, keyword);

    // 限制最大数量 (例如 20 条)
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }

    await _storage.put(BoxNames.cache, CacheKeys.searchHistory, history);
  }

  /// 删除单条历史
  Future<void> removeSearchHistory(String keyword) async {
    List<String> history = await getSearchHistory();
    history.remove(keyword);
    await _storage.put(BoxNames.cache, CacheKeys.searchHistory, history);
  }

  /// 清空所有历史
  Future<void> clearSearchHistory() async {
    await _storage.delete(BoxNames.cache, CacheKeys.searchHistory);
  }
  // ------------------------------- 播放状态 -------------------------------

  Future<void> savePlayerState(AppPlayerState state) async {
    await _storage.put(BoxNames.history, CacheKeys.playerState, state);
  }
  Future<AppPlayerState?> getPlayerState() async {
    final obj = await _storage.get(BoxNames.history, CacheKeys.playerState);
    if (obj is AppPlayerState) return obj;
    return null;
  }
  // --------------------------------分类配置信息 ----------------------------
  Future<void> saveTagsOption(List<Map<String, dynamic>> value, [Duration? expire]) async {
    await _saveWithExpire(CacheKeys.tagOption, value, expire);
  }

  Future<List<Map<String, dynamic>>?> getTagsOption() async {
    final value = await _getWithExpire(CacheKeys.tagOption);
    if (value is List) {
      return value.map((e) => OtherUtil.deepConvert(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveVasOption(List<Map<String, dynamic>> value, [Duration? expire]) async {
    await _saveWithExpire(CacheKeys.vasOption, value, expire);
  }

  Future<List<Map<String, dynamic>>?> getVasOption() async {
    final value = await _getWithExpire(CacheKeys.vasOption);
    if (value is List) {
      return value.map((e) => OtherUtil.deepConvert(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveCircleOption(List<Map<String, dynamic>> value, [Duration? expire]) async {
    await _saveWithExpire(CacheKeys.circleOption, value, expire);
  }

  Future<List<Map<String, dynamic>>?> getCircleOption() async {
    final value = await _getWithExpire(CacheKeys.circleOption);
    if (value is List) {
      return value.map((e) => OtherUtil.deepConvert(e as Map)).toList();
    }
    return null;
  }
  // ----------------------------- 扫描路径缓存  -------------------------

  String _getPathKey(ScanMode mode) {
    switch (mode) {
      case ScanMode.audio:
        return StorageKeys.scannerAudioPath;
      case ScanMode.video:
        return StorageKeys.scannerVideoPath;
      case ScanMode.subtitles:
        return StorageKeys.scannerSubtitlePath;
    }
  }

  // --- 内部辅助方法：根据模式获取 Item Key ---
  String _getItemKey(ScanMode mode) {
    switch (mode) {
      case ScanMode.audio:
        return StorageKeys.scannerAudioItem;
      case ScanMode.video:
        return StorageKeys.scannerVideoItem;
      case ScanMode.subtitles:
        return StorageKeys.scannerSubtitleItem;
    }
  }

  /// 保存用户添加的扫描根路径列表
  /// [修改] 参数由 bool isAudio 改为 ScanMode mode
  Future<void> saveScanRootPaths(List<String> paths, {required ScanMode mode}) async {
    final key = _getPathKey(mode);
    await _storage.put(BoxNames.scanner, key, paths);
  }

  /// 获取保存的扫描路径列表
  /// [修改] 参数由 bool isAudio 改为 ScanMode mode
  Future<List<String>> getScanRootPaths({required ScanMode mode}) async {
    final key = _getPathKey(mode);

    final list = await _storage.get(BoxNames.scanner, key);
    if (list is List) {
      return list.cast<String>();
    }
    return [];
  }

  /// 保存扫描结果
  /// [修改] 参数由 bool isAudio 改为 ScanMode mode
  Future<void> saveScanResults(List<AppMediaItem> items, {required ScanMode mode}) async {
    final key = _getItemKey(mode);

    // 将对象转为 List<Map>
    final jsonList = items.map((e) => e.toJson()).toList();

    await _storage.put(BoxNames.scanner, key, jsonList);
  }

  /// 清除扫描结果
  /// [修改] 参数由 bool isAudio 改为 ScanMode mode
  Future<void> clearScanResults({required ScanMode mode}) async {
    final key = _getItemKey(mode);
    await _storage.delete(BoxNames.scanner, key);
  }

  /// 获取缓存的扫描结果
  /// [修改] 参数由 bool isAudio 改为 ScanMode mode
  Future<List<AppMediaItem>> getCachedScanResults({required ScanMode mode}) async {
    final key = _getItemKey(mode);

    final list = await _storage.get(BoxNames.scanner, key);

    if (list is List) {
      try {
        return list.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return AppMediaItem.fromJson(map);
        }).toList();
      } catch (e) {
        print("CacheService: 解析缓存失败 $e");
        return [];
      }
    }
    return [];
  }

  // ------------------------------- 播放历史 -------------------------------

  /// 获取历史列表
  Future<List<HistoryEntry>> getHistoryList() async {
    final list = await _storage.get(BoxNames.history, CacheKeys.history);
    if (list is List) {
      return List<HistoryEntry>.from(list);
    }
    return [];
  }

  /// 添加或更新历史记录（只保存当前曲目和进度）
  Future<void> saveOrUpdateHistory(
      HistoryEntry history) async {
    final list = await getHistoryList();
    final work = history.work;
    // 找到已有记录
    HistoryEntry? existing = list.where((e) => e.work.id == work.id).firstOrNull;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 从 playerState 提取最后播放曲目和进度
    final lastTrackId = history.lastTrackId;
    final currentTrackTitle = history.currentTrackTitle;
    final lastProgressMs = history.lastProgressMs;

    if (existing != null) {
      // 更新已有记录
      final updated = existing.copyWith(
        lastTrackId: lastTrackId,
        currentTrackTitle: currentTrackTitle,
        lastProgressMs: lastProgressMs,
        updatedAt: now,
      );

      list.remove(existing);
      list.insert(0, updated);
    } else {
      // 新增记录
      final newEntry = HistoryEntry(
        work: work,
        lastTrackId: lastTrackId,
        currentTrackTitle: currentTrackTitle,
        lastProgressMs: lastProgressMs,
        updatedAt: now,
      );

      list.insert(0, newEntry);
    }

    // 控制最大数量
    if (list.length > _maxHistory) {
      list.removeRange(_maxHistory, list.length);
    }

    await _storage.put(BoxNames.history, CacheKeys.history, list);
  }

  /// 外部调用的新增接口
  Future<void> addToHistory(HistoryEntry history) async {
    await saveOrUpdateHistory(history);
  }


  // ------------------------------ 清理 ------------------------------

  Future<void> clearBoxFile(String boxName) async {
    // 1. 如果 Box 已打开，Hive 提供了标准清除方法
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
      return;
    }

    // 2. 如果 Box 没打开，手动删除文件
    try {
      final dir = await getApplicationDocumentsDirectory();
      final boxPath = '${dir.path}/hive_storage/$boxName.hive';
      final file = File(boxPath);

      if (await file.exists()) {
        await file.delete();
      }

      // 同时清理可能存在的锁文件 (.lock)
      final lockFile = File('$boxPath.lock');
      if (await lockFile.exists()) {
        await lockFile.delete();
      }
    } catch (e) {
      print("Error clearing box file: $e");
    }
  }
  Future<int> getBoxFileSize(String boxName) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final filePath = '${dir.path}/hive_storage/$boxName.hive';
      final file = File(filePath);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print("Error calculating box size for $boxName: $e");
      return 0;
    }
  }

}

