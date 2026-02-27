// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileNodeAdapter extends TypeAdapter<FileNode> {
  @override
  final typeId = 10;

  @override
  FileNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileNode(
      type: fields[0] as NodeType,
      title: fields[1] as String,
      hash: fields[2] as String?,
      mediaStreamUrl: fields[3] as String?,
      mediaDownloadUrl: fields[4] as String?,
      duration: (fields[5] as num?)?.toDouble(),
      size: (fields[6] as num?)?.toInt(),
      workTitle: fields[7] as String?,
      work: fields[8] as Work?,
      artist: fields[9] as String?,
      lastModified: fields[10] == null ? 0 : (fields[10] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, FileNode obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.hash)
      ..writeByte(3)
      ..write(obj.mediaStreamUrl)
      ..writeByte(4)
      ..write(obj.mediaDownloadUrl)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.size)
      ..writeByte(7)
      ..write(obj.workTitle)
      ..writeByte(8)
      ..write(obj.work)
      ..writeByte(9)
      ..write(obj.artist)
      ..writeByte(10)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
          : Work.fromJson(json['work'] as Map<String, dynamic>),
      artist: json['artist'] as String?,
      lastModified: (json['lastModified'] as num?)?.toInt() ?? 0,
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
      'lastModified': instance.lastModified,
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
