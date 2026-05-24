import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/history_entry.dart';
import '../../data/repository/history_respository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository.instance;
});

final historyControllerProvider =
    NotifierProvider<HistoryController, List<HistoryEntry>>(
      HistoryController.new,
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

final historyByTypeProvider =
    Provider.family<List<HistoryEntry>, HistoryEntryType>((ref, type) {
      final entries = ref.watch(historyControllerProvider);
      return entries.where((entry) => entry.historyType == type).toList();
    });

final historyPreviewByTypeProvider =
    Provider.family<List<HistoryEntry>, HistoryEntryType>((ref, type) {
      return ref.watch(historyByTypeProvider(type)).take(20).toList();
    });
