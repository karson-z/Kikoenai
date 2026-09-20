import 'package:kikoenai_core/kikoenai_core.dart';

/// 旧版"按作品作用域"历史 → 新版"按会话"历史的一次性数据迁移。
///
/// 旧 Box 中每个作用域一条记录、内嵌完整队列快照，且混合队列会让
/// 多条记录共享同一个 [PlaybackSession.id]；迁移把键统一改写为
/// session.id（重复 id 只保留 lastPlayTime 最新的一条），并顺带推导出
/// 每个作用域的作品断点进度索引。
abstract final class HistoryMigration {
  /// 输入旧版全部历史条目，输出会话表与进度索引表（均为"新者胜"）。
  static HistoryMigrationResult buildSessionMaps(List<HistoryEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => b.lastPlayTime.compareTo(a.lastPlayTime));

    final sessions = <String, HistoryEntry>{};
    final progress = <String, WorkProgressPoint>{};

    for (final entry in sorted) {
      final item = entry.lastItem;
      // 空队列或定位不到曲目的脏数据直接丢弃。
      if (item == null || entry.session.queue.isEmpty) continue;

      final sessionId = entry.session.id;
      if (sessionId.isNotEmpty && !sessions.containsKey(sessionId)) {
        sessions[sessionId] = entry;
      }

      final scopeKey = item.scopeKey;
      if (!progress.containsKey(scopeKey)) {
        progress[scopeKey] = WorkProgressPoint(
          scopeKey: scopeKey,
          itemId: entry.lastItemId,
          progressMs: entry.lastProgressMs ?? 0,
          updatedAt: entry.lastPlayTime,
          sessionId: sessionId,
        );
      }
    }

    return HistoryMigrationResult(sessions: sessions, progress: progress);
  }
}

class HistoryMigrationResult {
  const HistoryMigrationResult({
    required this.sessions,
    required this.progress,
  });

  /// 会话历史表，key 为 session.id。
  final Map<String, HistoryEntry> sessions;

  /// 作品断点进度索引，key 为 scopeKey。
  final Map<String, WorkProgressPoint> progress;
}
