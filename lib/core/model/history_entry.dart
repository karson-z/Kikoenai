import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../features/album/data/model/work.dart';
import '../constants/app_typeIds.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

@freezed
@HiveType(typeId: TypeIds.historyEntry, adapterName: 'HistoryEntryAdapter')
abstract class HistoryEntry with _$HistoryEntry {
  const HistoryEntry._();

  const factory HistoryEntry({
    @HiveField(0)
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _workFromJson, toJson: _workToJson)
    required Work work,
    @HiveField(1) required int updatedAt,
    @HiveField(2) String? lastTrackId,
    @HiveField(3) String? currentTrackTitle,
    @HiveField(4) int? lastProgressMs,
    @HiveField(5) @Default(false) bool isLocal,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntryFromJson(json);

  Map<String, dynamic> toMap() => toJson();

  factory HistoryEntry.fromMap(Map<String, dynamic> map) =>
      HistoryEntry.fromJson(map);
}

Work _workFromJson(Map<String, dynamic> json) => Work.fromJson(json);

Map<String, dynamic> _workToJson(Work work) => work.toJson();
