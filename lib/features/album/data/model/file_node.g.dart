// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileNode _$FileNodeFromJson(Map<String, dynamic> json) => FileNode(
      type: $enumDecode(_$NodeTypeEnumMap, json['type']),
      title: json['title'] as String,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => FileNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      hash: json['hash'] as String?,
      mediaStreamUrl: json['mediaStreamUrl'] as String?,
      mediaDownloadUrl: json['mediaDownloadUrl'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      size: (json['size'] as num?)?.toInt(),
      workTitle: json['workTitle'] as String?,
      work: json['work'] == null
          ? null
          : WorkInfo.fromJson(json['work'] as Map<String, dynamic>),
      artist: json['artist'] as String?,
    );

Map<String, dynamic> _$FileNodeToJson(FileNode instance) => <String, dynamic>{
      'type': _$NodeTypeEnumMap[instance.type]!,
      'title': instance.title,
      'children': instance.children,
      'hash': instance.hash,
      'mediaStreamUrl': instance.mediaStreamUrl,
      'mediaDownloadUrl': instance.mediaDownloadUrl,
      'duration': instance.duration,
      'size': instance.size,
      'workTitle': instance.workTitle,
      'work': instance.work,
      'artist': instance.artist,
    };

const _$NodeTypeEnumMap = {
  NodeType.folder: 'folder',
  NodeType.audio: 'audio',
  NodeType.image: 'image',
  NodeType.text: 'text',
  NodeType.video: 'video',
  NodeType.other: 'other',
  NodeType.unknown: 'unknown',
};
