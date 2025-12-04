import 'dart:io';
import 'package:hive/hive.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/album/data/model/work.dart';
import '../model/history_entry.dart';
import '../storage/hive_box.dart';
import '../storage/hive_key.dart';
import '../storage/hive_storage.dart';
import '../widgets/player/state/player_state.dart';

/// ---------------------- CacheService 单例 ----------------------
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
  // ------------------------------- 播放状态 -------------------------------

  Future<void> savePlayerState(AppPlayerState state) async {
    await _storage.put(BoxNames.cache, CacheKeys.playerState, state);
  }
  Future<AppPlayerState?> getPlayerState() async {
    final obj = await _storage.get(BoxNames.cache, CacheKeys.playerState);
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
    // 如果 Box 已打开，直接清空
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
      return;
    }

    // 如果 Box 没打开，先打开再清空
    final box = await Hive.openBox(boxName);
    await box.clear();
    await box.close();
  }
  Future<int> getBoxFileSize(String boxName) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationDocumentsDirectory();
      final boxDir = Directory('${dir.path}/hive_storage/$boxName');

      if (!await boxDir.exists()) return 0;

      return _getDirectorySize(boxDir);
    } else {
      // 移动端 — Hive 默认在 app doc dir 下，文件名 = boxName.hive
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$boxName.hive');

      if (await file.exists()) {
        return file.length();
      }
      return 0;
    }
  }
  /// 递归目录大小
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;

    if (!await dir.exists()) return 0;

    final entities = dir.list(recursive: true, followLinks: false);
    await for (final entity in entities) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }
}

