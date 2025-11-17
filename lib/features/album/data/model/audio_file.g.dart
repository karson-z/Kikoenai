// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioFile _$AudioFileFromJson(Map<String, dynamic> json) => AudioFile(
      title: json['title'] as String,
      type: json['type'] as String?,
      hash: json['hash'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => AudioFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaDownloadUrl: json['mediaDownloadUrl'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AudioFileToJson(AudioFile instance) => <String, dynamic>{
      'title': instance.title,
      'type': instance.type,
      'hash': instance.hash,
      'children': instance.children,
      'mediaDownloadUrl': instance.mediaDownloadUrl,
      'size': instance.size,
    };
