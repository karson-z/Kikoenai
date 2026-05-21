import 'package:freezed_annotation/freezed_annotation.dart';
import 'file_node.dart';

part 'player_queue.freezed.dart';
part 'player_queue.g.dart';

@freezed
abstract class PlayerQueue with _$PlayerQueue {
  const factory PlayerQueue({
    String? workId,
    required List<FileNode> playlist,
    String? lastPlayTrackId,
    @Default(0) int progressMs,
  }) = _PlayerQueue;

  factory PlayerQueue.fromJson(Map<String, dynamic> json) => _$PlayerQueueFromJson(json);
}

@freezed
abstract class PlayerQueueWithLastPlayDate with _$PlayerQueueWithLastPlayDate {
  const factory PlayerQueueWithLastPlayDate({
    required PlayerQueue queue,
    required DateTime lastPlayDate,
  }) = _PlayerQueueWithLastPlayDate;

  factory PlayerQueueWithLastPlayDate.fromJson(Map<String, dynamic> json) =>
      _$PlayerQueueWithLastPlayDateFromJson(json);
}