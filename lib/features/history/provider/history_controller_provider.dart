import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kikoenai_core/core/model/history/history_entry.dart';
import 'history_respository.dart';
import 'work_progress_repository.dart';

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

  // 用于单次读取
  HistoryEntry? getLatestOne() {
    final list = getAll();
    return list.isNotEmpty ? list.first : null;
  }

  // 用于单次读取
  List<HistoryEntry> getAll() {
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
    await delete(entry.session.id);
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    await _repository.deleteAll(ids);
    state = _repository.getAll();
  }

  /// 清空历史：会话时间线与作品断点进度一并清除，两者对用户是同一份"历史"。
  Future<void> clear() async {
    await _repository.clear();
    await WorkProgressRepository.instance.clear();
    state = const [];
  }
}
