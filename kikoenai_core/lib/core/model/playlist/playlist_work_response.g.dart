// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_work_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaylistWorksResponse _$PlaylistWorksResponseFromJson(
  Map<String, dynamic> json,
) => _PlaylistWorksResponse(
  works:
      (json['works'] as List<dynamic>?)
          ?.map((e) => Work.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlaylistWorksResponseToJson(
  _PlaylistWorksResponse instance,
) => <String, dynamic>{
  'works': instance.works,
  'pagination': instance.pagination,
};
