import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../../../../core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository.instance;
});
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

  /// 根据来源分类获取历史列表 (按时间倒序)
  List<HistoryEntry> getBySource(NodeSource source) {
    final list = _box.values.where((entry) => entry.source == source).toList();
    list.sort((a, b) => b.lastPlayTime.compareTo(a.lastPlayTime));
    return list;
  }

  /// 根据唯一标识获取单条历史记录
  /// [id] primaryKey
  HistoryEntry? getById(String id) {
    return _box.get(id);
  }

  /// 添加或更新历史记录
  Future<void> save(HistoryEntry entry) async {
    final key = entry.primaryKey;
    await _box.put(key, entry);
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
}