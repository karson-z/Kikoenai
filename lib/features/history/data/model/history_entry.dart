import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';

import '../../../album/data/model/work.dart';
import '../../../../core/constants/app_typeIds.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

// 必须给 Enum 加上 HiveType 和 HiveField，否则存入时会报错
@HiveType(typeId: TypeIds.historyEntryType, adapterName: 'HistoryEntryTypeAdapter')
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
    @HiveField(0)
    Work? work,

    @HiveField(1)
    MediaItem? lastPlayTrack,

    @HiveField(2)
    required int lastPlayTime,

    @HiveField(3)
    String? lastTrackId,

    @HiveField(4)
    String? currentTrackTitle,

    @HiveField(5)
    int? lastProgressMs,

    @HiveField(6)
    @Default(HistoryEntryType.work) HistoryEntryType historyType,
  }) = _HistoryEntry;

  /// 作为历史记录的唯一键，根据不同的类型生成
  String get primaryKey {
    // 提取可用的实体 ID
    final entityId = work?.id.toString() ?? lastTrackId;

    // 极端情况兜底：如果都没有，则用时间戳（虽然业务上不应该出现都没有的情况）
    final fallbackId = entityId ?? lastPlayTime.toString();

    switch (historyType) {
      case HistoryEntryType.work:
      // 网络作品：以 work_ 为前缀
        return 'work_$fallbackId';

      case HistoryEntryType.localWork:
      // 本地作品：以 local_work_ 为前缀
        return 'local_work_$fallbackId';

      case HistoryEntryType.singleWork:
      // 单曲：以 single_ 为前缀
      // 单曲可能没有 work 对象，此时 fallbackId 自然取到了 lastTrackId (通常是文件 hash)
        return 'single_$fallbackId';
    }
  }
}
