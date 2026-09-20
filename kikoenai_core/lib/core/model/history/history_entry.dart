import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

/// 一次播放会话的历史记录（Box key: session.id）。
///
/// 恢复时原样还原整个队列，不按作用域裁剪；作品维度的断点续播
/// 由 [WorkProgressPoint] 索引承担。
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

  bool get isNetworkWork =>
      source == NodeSource.asmrServer || source == NodeSource.asmrGay;

  bool get isLocalWork => source == NodeSource.localWork;

  bool get isLocalSingle => source == NodeSource.localSingle;
}
