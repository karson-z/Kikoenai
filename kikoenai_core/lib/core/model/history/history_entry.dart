import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

@freezed
@HiveType(typeId: TypeIds.historyEntry, adapterName: 'HistoryEntryAdapter')
abstract class HistoryEntry with _$HistoryEntry {
  const HistoryEntry._();

  const factory HistoryEntry({
    @HiveField(6) required PlaybackSession session,
    @HiveField(7) required String lastItemId,
    @HiveField(8) required int lastPlayTime,
    @HiveField(9) int? lastProgressMs,
  }) = _HistoryEntry;

  PlaybackItem? get lastItem =>
      session.itemById(lastItemId) ?? session.currentItem;

  NodeSource? get source => lastItem?.source;

  String? get workId => lastItem?.workId?.toString();

  String? get siteId => lastItem?.contentId?.siteId;

  String? get remoteId => lastItem?.contentId?.remoteId;

  String get lastTrackId => lastItemId;

  String get currentTrackTitle => lastItem?.title ?? '';

  String? get title => lastItem?.albumTitle ?? lastItem?.title;

  String? get coverUrl => lastItem?.coverUrl ?? lastItem?.smallCoverUrl;

  Duration? get duration => lastItem?.duration;

  bool get isNetworkWork => source == NodeSource.asmrServer;

  bool get isLocalWork => source == NodeSource.localWork;

  bool get isLocalSingle => source == NodeSource.localSingle;

  /// Session used when the user resumes this history entry.
  ///
  /// A history entry may be saved from a mixed playback queue, but the resume
  /// action should only restore the queue that belongs to this entry's
  /// aggregation scope.
  PlaybackSession get restoreSession {
    final anchor = lastItem;
    if (anchor == null) return session;

    final scopedQueue = session.queue
        .where((item) => _isSameHistoryScope(anchor, item))
        .toList(growable: false);
    if (scopedQueue.isEmpty) return session;

    final scopedIndex = scopedQueue.indexWhere((item) => item.id == lastItemId);
    return session.copyWith(
      queue: scopedQueue,
      currentIndex: scopedIndex < 0 ? 0 : scopedIndex,
    );
  }

  String get primaryKey {
    final item = lastItem;
    if (item == null) return 'unknown_$lastItemId';

    return switch (item.source) {
      NodeSource.asmrServer =>
        item.siteId == null
            ? 'work_${item.scopeId}'
            : 'work_${item.contentId!.storageKey}',
      NodeSource.localWork => 'local_work_${item.scopeId}',
      NodeSource.localSingle => 'single_${item.id}',
      NodeSource.cloudDrive => 'cloud_${item.scopeId}',
    };
  }

  bool _isSameHistoryScope(PlaybackItem anchor, PlaybackItem item) {
    if (anchor.source != item.source) return false;
    if (anchor.contentId?.siteId != item.contentId?.siteId) return false;
    return switch (anchor.source) {
      NodeSource.localSingle => item.id == anchor.id,
      NodeSource.asmrServer ||
      NodeSource.localWork ||
      NodeSource.cloudDrive => item.scopeId == anchor.scopeId,
    };
  }
}
