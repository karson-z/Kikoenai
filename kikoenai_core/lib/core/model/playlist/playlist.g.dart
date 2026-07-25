// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Playlist _$PlaylistFromJson(Map<String, dynamic> json) => _Playlist(
  id: json['id'] as String,
  userName: json['user_name'] as String? ?? '',
  privacy: (json['privacy'] as num?)?.toInt() ?? 0,
  locale: json['locale'] as String? ?? 'zh-CN',
  playbackCount: (json['playback_count'] as num?)?.toInt() ?? 0,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
  latestWorkId: (json['latestWorkID'] as num?)?.toInt(),
  mainCoverUrl: json['mainCoverUrl'] as String?,
);

Map<String, dynamic> _$PlaylistToJson(_Playlist instance) => <String, dynamic>{
  'id': instance.id,
  'user_name': instance.userName,
  'privacy': instance.privacy,
  'locale': instance.locale,
  'playback_count': instance.playbackCount,
  'name': instance.name,
  'description': instance.description,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'works_count': instance.worksCount,
  'latestWorkID': instance.latestWorkId,
  'mainCoverUrl': instance.mainCoverUrl,
};
