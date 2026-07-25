import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kikoenai_core/core/model/local_media/file_node.dart';
import 'package:kikoenai_core/core/model/history/history_entry.dart';
import '../../data/repository/history_respository.dart';

final historyControllerProvider =
NotifierProvider<HistoryController, List<HistoryEntry>>(
  HistoryController.new,
);

final historyBySourceProvider = Provider.family<List<HistoryEntry>, NodeSource>(
      (ref, source) {
    final entries = ref.watch(historyControllerProvider);
    return entries.where((entry) => entry.source == source).toList();
  },
);

class HistoryController extends Notifier<List<HistoryEntry>> {
  HistoryRepository get _repository => ref.read(historyRepositoryProvider);

  @override
  List<HistoryEntry> build() {
    final subscription = _repository.watch().listen((_) {
      state = _repository.getAll();
    });

    ref.onDispose(subscription.cancel);

    return _repository.getAll();
  }
  // 用于单次读取
  List<HistoryEntry> getEntriesBySource(NodeSource source) {
    return _repository.getBySource(source);
  }
  // 用于单次读取
  HistoryEntry? getLatestOne() {
    final list = getAll();
    return list.isNotEmpty ? list.first : null;
  }
  // 用于单次读取
  List<HistoryEntry> getAll(){
    return _repository.getAll();
  }

  Future<void> reload() async {
    state = _repository.getAll();
  }

  Future<void> upsert(HistoryEntry entry) async {
    await _repository.save(entry);
    state = _repository.getAll();
  }

  Future<void> remove(HistoryEntry entry) async {
    await delete(entry.primaryKey);
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    await _repository.deleteAll(ids);
    state = _repository.getAll();
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const [];
  }
}