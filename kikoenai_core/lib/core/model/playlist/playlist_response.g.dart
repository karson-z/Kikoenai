// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaylistListResponse _$PlaylistListResponseFromJson(
  Map<String, dynamic> json,
) => _PlaylistListResponse(
  playlists:
      (json['playlists'] as List<dynamic>?)
          ?.map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlaylistListResponseToJson(
  _PlaylistListResponse instance,
) => <String, dynamic>{
  'playlists': instance.playlists,
  'pagination': instance.pagination,
};
