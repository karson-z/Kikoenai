import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/player/data/model/playback_session.dart';

part 'history_entry.freezed.dart';

@Deprecated('Only kept for reading legacy Hive history entries.')
enum HistoryEntryType { work, localWork, singleWork }

@freezed
abstract class HistoryEntry with _$HistoryEntry {
  const HistoryEntry._();

  const factory HistoryEntry({
    required PlaybackSession session,
    required String lastItemId,
    required int lastPlayTime,
    int? lastProgressMs,
  }) = _HistoryEntry;

  PlaybackItem? get lastItem =>
      session.itemById(lastItemId) ?? session.currentItem;

  NodeSource? get source => lastItem?.source;

  String? get workId => lastItem?.workId?.toString();

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
      NodeSource.asmrServer => 'work_${item.scopeId}',
      NodeSource.localWork => 'local_work_${item.scopeId}',
      NodeSource.localSingle => 'single_${item.id}',
      NodeSource.cloudDrive => 'cloud_${item.scopeId}',
    };
  }

  bool _isSameHistoryScope(PlaybackItem anchor, PlaybackItem item) {
    if (anchor.source != item.source) return false;
    return switch (anchor.source) {
      NodeSource.localSingle => item.id == anchor.id,
      NodeSource.asmrServer ||
      NodeSource.localWork ||
      NodeSource.cloudDrive => item.scopeId == anchor.scopeId,
    };
  }
}

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  int get typeId => TypeIds.historyEntry;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final session = fields[6] as PlaybackSession?;
    if (session != null) {
      return HistoryEntry(
        session: session,
        lastItemId: fields[7] as String? ?? session.currentItem?.id ?? '',
        lastPlayTime:
            (fields[8] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        lastProgressMs: (fields[9] as num?)?.toInt(),
      );
    }

    return _readLegacyEntry(fields);
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(6)
      ..write(obj.session)
      ..writeByte(7)
      ..write(obj.lastItemId)
      ..writeByte(8)
      ..write(obj.lastPlayTime)
      ..writeByte(9)
      ..write(obj.lastProgressMs);
  }

  HistoryEntry _readLegacyEntry(Map<int, dynamic> fields) {
    final work = fields[0] as Work?;
    final lastPlayTrack = fields[1] as MediaItem?;
    final playlist = (fields[2] as List?)?.cast<MediaItem>();
    final lastPlayTime =
        (fields[3] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    final lastProgressMs = (fields[4] as num?)?.toInt();
    final historyType = fields[5] as HistoryEntryType?;
    final source = _legacySource(historyType, lastPlayTrack);
    final mediaItems = playlist?.isNotEmpty == true
        ? playlist!
        : lastPlayTrack == null
        ? const <MediaItem>[]
        : <MediaItem>[lastPlayTrack];
    final items = mediaItems
        .map(
          (item) =>
              PlaybackItem.fromMediaItem(item, work: work, source: source),
        )
        .toList();
    final lastItemId =
        lastPlayTrack?.id ?? (items.isEmpty ? '' : items.first.id);
    final currentIndex = items.indexWhere((item) => item.id == lastItemId);

    return HistoryEntry(
      session: PlaybackSession(
        id: 'legacy_$lastItemId',
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        queue: items,
        createdAt: lastPlayTime,
        updatedAt: lastPlayTime,
      ),
      lastItemId: lastItemId,
      lastPlayTime: lastPlayTime,
      lastProgressMs: lastProgressMs,
    );
  }

  NodeSource _legacySource(HistoryEntryType? type, MediaItem? item) {
    return switch (type) {
      HistoryEntryType.work => NodeSource.asmrServer,
      HistoryEntryType.localWork => NodeSource.localWork,
      HistoryEntryType.singleWork => NodeSource.localSingle,
      null => _legacySourceFromMediaItem(item),
    };
  }

  NodeSource _legacySourceFromMediaItem(MediaItem? item) {
    final url = item?.extras?['url'] as String?;
    if (url == null) return NodeSource.asmrServer;
    if (url.startsWith('/') || url.startsWith('file://')) {
      return NodeSource.localWork;
    }
    return NodeSource.asmrServer;
  }
}

class HistoryEntryTypeAdapter extends TypeAdapter<HistoryEntryType> {
  @override
  int get typeId => TypeIds.historyEntryType;

  @override
  HistoryEntryType read(BinaryReader reader) {
    return switch (reader.readByte()) {
      0 => HistoryEntryType.work,
      1 => HistoryEntryType.localWork,
      2 => HistoryEntryType.singleWork,
      _ => HistoryEntryType.work,
    };
  }

  @override
  void write(BinaryWriter writer, HistoryEntryType obj) {
    writer.writeByte(switch (obj) {
      HistoryEntryType.work => 0,
      HistoryEntryType.localWork => 1,
      HistoryEntryType.singleWork => 2,
    });
  }
}
