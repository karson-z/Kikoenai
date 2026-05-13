import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../album/data/model/work.dart';
import '../../../../core/constants/app_typeIds.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

// 必须给 Enum 加上 HiveType 和 HiveField，否则存入时会报错
@HiveType(
    typeId: TypeIds.historyEntryType, adapterName: 'HistoryEntryTypeAdapter')
enum HistoryEntryType {
  @HiveField(0)
  work,
  @HiveField(1)
  localWork,
  @HiveField(2)
  singleWork,
}

@freezed
@HiveType(typeId: TypeIds.historyEntry, adapterName: 'HistoryEntryAdapter')
abstract class HistoryEntry with _$HistoryEntry {
  const HistoryEntry._();

  const factory HistoryEntry({
    @HiveField(0) Work? work,
    @HiveField(1) required MediaItem lastPlayTrack,
    @HiveField(2) required List<MediaItem>? playlist,
    @HiveField(3) required int lastPlayTime,
    @HiveField(4) int? lastProgressMs,
    @HiveField(5) @Default(HistoryEntryType.work) HistoryEntryType historyType,
  }) = _HistoryEntry;

  String get lastTrackId => lastPlayTrack.id;

  String get currentTrackTitle => lastPlayTrack.title;

  /// 作为历史记录的唯一键，根据不同的类型生成
  String get primaryKey {
    // 提取可用的实体 ID
    final entityId = work?.id.toString() ?? lastPlayTrack.id;

    switch (historyType) {
      case HistoryEntryType.work:
        // 网络作品：以 work_ 为前缀
        return 'work_$entityId';

      case HistoryEntryType.localWork:
        // 本地作品：以 local_work_ 为前缀
        return 'local_work_$entityId';

      case HistoryEntryType.singleWork:
        // 单曲：以 single_ 为前缀
        // 单曲可能没有 work 对象，此时 entityId 自然取到了 lastTrackId (通常是文件 hash)
        return 'single_$entityId';
    }
  }
}
