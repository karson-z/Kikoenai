import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../../../../core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository.instance;
});

/// 会话历史的容量上限：每条内嵌整队列快照，超过后从最旧的开始修剪。
const _maxSessionCount = 300;

class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  Box<HistoryEntry> get _box => AppStorage.historyBox;

  Stream<BoxEvent> watch() {
    return _box.watch();
  }

  /// 获取所有历史列表 (按时间倒序)
  List<HistoryEntry> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.lastPlayTime.compareTo(a.lastPlayTime));
    return list;
  }

  /// 根据会话 id 获取单条历史记录
  HistoryEntry? getById(String id) {
    return _box.get(id);
  }

  /// 添加或更新历史记录（同一会话恢复播放时原地更新，不产生新条目）
  Future<void> save(HistoryEntry entry) async {
    await _box.put(entry.session.id, entry);
    await _pruneIfNeeded();
  }

  /// 删除单条历史记录
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 批量删除
  Future<void> deleteAll(Iterable<String> ids) async {
    await _box.deleteAll(ids);
  }

  /// 清空所有历史记录
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> _pruneIfNeeded() async {
    if (_box.length <= _maxSessionCount) return;
    final oldest = _box.values.toList()
      ..sort((a, b) => a.lastPlayTime.compareTo(b.lastPlayTime));
    final overflow = oldest.take(oldest.length - _maxSessionCount);
    await _box.deleteAll(overflow.map((entry) => entry.session.id));
  }
}
