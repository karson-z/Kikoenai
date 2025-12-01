import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/other.dart';

import '../storage/hive_box.dart';
import '../storage/hive_key.dart';
import '../storage/hive_storage.dart';

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
  // ------------------------------- 播放列表 -------------------------------

  Future<void> savePlaylist(List<Map<String, dynamic>> playlist) async {
    // 转成 JSON 字符串存储
    final jsonString = jsonEncode(playlist);
    await _storage.put(BoxNames.cache, CacheKeys.playlist, jsonString);
    debugPrint('savePlaylist: 成功保存当前列表');
  }

  Future<List<Map<String, dynamic>>> getPlaylist() async {
    final jsonString = await _storage.get(BoxNames.cache, CacheKeys.playlist);
    if (jsonString is String && jsonString.isNotEmpty) {
      try {
        final list = jsonDecode(jsonString);
        if (list is List) {
          return List<Map<String, dynamic>>.from(list);
        }
      } catch (e) {
        debugPrint('getPlaylist: 解析 JSON 失败 $e');
      }
    }
    return [];
  }

  // --------------------------- 当前播放曲目 ------------------------------

  Future<void> saveCurrentTrack(Map<String, dynamic>? track) async {
    await _storage.put(BoxNames.cache, CacheKeys.currentTrack, track);
  }

  Future<Map<String, dynamic>?> getCurrentTrack() async {
    final track = await _storage.get(BoxNames.cache, CacheKeys.currentTrack);
    if (track is Map) return Map<String, dynamic>.from(track);
    return null;
  }

  Future<void> saveCurrentIndex(int index) async {
    await _storage.put(BoxNames.cache, CacheKeys.currentIndex, index);
  }

  Future<int?> getCurrentIndex() async {
    final value = await _storage.get(BoxNames.cache, CacheKeys.currentIndex);
    return value is int ? value : null;
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

  Future<void> addToHistory(Map<String, dynamic> track) async {
    final history = await getHistory();

    history.removeWhere((t) => t['id'] == track['id']);
    history.insert(0, track);

    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }

    await _storage.put(BoxNames.cache, CacheKeys.history, history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final list = await _storage.get(BoxNames.cache, CacheKeys.history);
    if (list is List) return List<Map<String, dynamic>>.from(list);
    return [];
  }

  // ------------------------------ 清理 ------------------------------

  Future<void> clearPlaylist() async {
    await _storage.delete(BoxNames.cache, CacheKeys.playlist);
  }

  Future<void> clearCurrentTrack() async {
    await _storage.delete(BoxNames.cache, CacheKeys.currentTrack);
    await _storage.delete(BoxNames.cache, CacheKeys.currentIndex);
  }
  Future<void> clearOption () async{
    await _storage.delete(BoxNames.cache, CacheKeys.circleOption);
    await _storage.delete(BoxNames.cache, CacheKeys.tagOption);
    await _storage.delete(BoxNames.cache, CacheKeys.vasOption);
  }
  Future<void> clearHistory() async {
    await _storage.delete(BoxNames.cache, CacheKeys.history);
  }
}
