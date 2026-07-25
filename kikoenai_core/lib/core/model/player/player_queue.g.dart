// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerQueue _$PlayerQueueFromJson(Map<String, dynamic> json) => _PlayerQueue(
  workId: json['workId'] as String?,
  playlist: (json['playlist'] as List<dynamic>)
      .map((e) => FileNode.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastPlayTrackId: json['lastPlayTrackId'] as String?,
  progressMs: (json['progressMs'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PlayerQueueToJson(_PlayerQueue instance) =>
    <String, dynamic>{
      'workId': instance.workId,
      'playlist': instance.playlist,
      'lastPlayTrackId': instance.lastPlayTrackId,
      'progressMs': instance.progressMs,
    };

_PlayerQueueWithLastPlayDate _$PlayerQueueWithLastPlayDateFromJson(
  Map<String, dynamic> json,
) => _PlayerQueueWithLastPlayDate(
  queue: PlayerQueue.fromJson(json['queue'] as Map<String, dynamic>),
  lastPlayDate: DateTime.parse(json['lastPlayDate'] as String),
);

Map<String, dynamic> _$PlayerQueueWithLastPlayDateToJson(
  _PlayerQueueWithLastPlayDate instance,
) => <String, dynamic>{
  'queue': instance.queue,
  'lastPlayDate': instance.lastPlayDate.toIso8601String(),
};
