import '../storage/hive_box.dart';
import '../storage/hive_key.dart';
import '../storage/hive_storage.dart';

class CacheService {
  /// 最大的历史记录
  static const int _maxHistory = 200;

  final HiveStorage _storage;

  CacheService(this._storage);

  // ------------------------------- 播放列表 -------------------------------

  Future<void> savePlaylist(List<Map<String, dynamic>> playlist) async {
    await _storage.put(BoxNames.cache, CacheKeys.playlist, playlist);
  }

  Future<List<Map<String, dynamic>>> getPlaylist() async {
    final list = await _storage.get(BoxNames.cache, CacheKeys.playlist);
    if (list is List) return List<Map<String, dynamic>>.from(list);
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
  // ------------------------------作品文件列表 ----------------------------
  // TODO 作品文件列表

  // ------------------------------ 清理 API ------------------------------

  Future<void> clearPlaylist() async {
    await _storage.delete(BoxNames.cache, CacheKeys.playlist);
  }

  Future<void> clearCurrentTrack() async {
    await _storage.delete(BoxNames.cache, CacheKeys.currentTrack);
    await _storage.delete(BoxNames.cache, CacheKeys.currentIndex);
  }

  Future<void> clearHistory() async {
    await _storage.delete(BoxNames.cache, CacheKeys.history);
  }


}
