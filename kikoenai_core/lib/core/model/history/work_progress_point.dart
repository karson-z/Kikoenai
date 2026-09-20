import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'work_progress_point.freezed.dart';
part 'work_progress_point.g.dart';

/// 作品维度的断点续播索引（Box key: scopeKey）。
///
/// 每个播放作用域（作品/单曲/云盘目录）只保留最新一条，与会话历史
/// （[HistoryEntry]，按时间线浏览）互不依赖：删除某个会话不影响其他
/// 会话内同一作品的续播进度。
@freezed
@HiveType(
  typeId: TypeIds.workProgressPoint,
  adapterName: 'WorkProgressPointAdapter',
)
abstract class WorkProgressPoint with _$WorkProgressPoint {
  const factory WorkProgressPoint({
    @HiveField(0) required String scopeKey,
    @HiveField(1) required String itemId,
    @HiveField(2) @Default(0) int progressMs,
    @HiveField(3) required int updatedAt,
    @HiveField(4) String? sessionId,
  }) = _WorkProgressPoint;
}
