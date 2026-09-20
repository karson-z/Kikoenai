import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../../../../core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

final workProgressRepositoryProvider = Provider<WorkProgressRepository>((ref) {
  return WorkProgressRepository.instance;
});

/// 作品断点续播进度索引：每个播放作用域只保留最新一条。
class WorkProgressRepository {
  WorkProgressRepository._();
  static final WorkProgressRepository instance = WorkProgressRepository._();

  Box<WorkProgressPoint> get _box => AppStorage.workProgressBox;

  WorkProgressPoint? getByScope(String scopeKey) {
    return _box.get(scopeKey);
  }

  Future<void> save(WorkProgressPoint point) async {
    await _box.put(point.scopeKey, point);
  }

  Future<void> delete(String scopeKey) async {
    await _box.delete(scopeKey);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
