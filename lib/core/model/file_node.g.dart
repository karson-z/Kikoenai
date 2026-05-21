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
      artist: fields[8] as String?,
      lastModified: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      nodeStatus: fields[10] == null
          ? NodeStatus.normal
          : fields[10] as NodeStatus,
      workId: (fields[11] as num?)?.toInt(),
      source: fields[12] as NodeSource,
    );
  }

  @override
  void write(BinaryWriter writer, FileNode obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.artist)
      ..writeByte(9)
      ..write(obj.lastModified)
      ..writeByte(10)
      ..write(obj.nodeStatus)
      ..writeByte(11)
      ..write(obj.workId)
      ..writeByte(12)
      ..write(obj.source);
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

class NodeSourceAdapter extends TypeAdapter<NodeSource> {
  @override
  final typeId = 15;

  @override
  NodeSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NodeSource.asmrServer;
      case 1:
        return NodeSource.localWork;
      case 2:
        return NodeSource.localSingle;
      case 3:
        return NodeSource.cloudDrive;
      default:
        return NodeSource.asmrServer;
    }
  }

  @override
  void write(BinaryWriter writer, NodeSource obj) {
    switch (obj) {
      case NodeSource.asmrServer:
        writer.writeByte(0);
      case NodeSource.localWork:
        writer.writeByte(1);
      case NodeSource.localSingle:
        writer.writeByte(2);
      case NodeSource.cloudDrive:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NodeTypeAdapter extends TypeAdapter<NodeType> {
  @override
  final typeId = 13;

  @override
  NodeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NodeType.folder;
      case 1:
        return NodeType.audio;
      case 2:
        return NodeType.image;
      case 3:
        return NodeType.text;
      case 4:
        return NodeType.video;
      case 5:
        return NodeType.other;
      case 6:
        return NodeType.unknown;
      default:
        return NodeType.folder;
    }
  }

  @override
  void write(BinaryWriter writer, NodeType obj) {
    switch (obj) {
      case NodeType.folder:
        writer.writeByte(0);
      case NodeType.audio:
        writer.writeByte(1);
      case NodeType.image:
        writer.writeByte(2);
      case NodeType.text:
        writer.writeByte(3);
      case NodeType.video:
        writer.writeByte(4);
      case NodeType.other:
        writer.writeByte(5);
      case NodeType.unknown:
        writer.writeByte(6);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NodeStatusAdapter extends TypeAdapter<NodeStatus> {
  @override
  final typeId = 14;

  @override
  NodeStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NodeStatus.normal;
      case 1:
        return NodeStatus.pending;
      case 2:
        return NodeStatus.parsing;
      case 3:
        return NodeStatus.parsed;
      default:
        return NodeStatus.normal;
    }
  }

  @override
  void write(BinaryWriter writer, NodeStatus obj) {
    switch (obj) {
      case NodeStatus.normal:
        writer.writeByte(0);
      case NodeStatus.pending:
        writer.writeByte(1);
      case NodeStatus.parsing:
        writer.writeByte(2);
      case NodeStatus.parsed:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileNode _$FileNodeFromJson(Map<String, dynamic> json) => _FileNode(
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
  artist: json['artist'] as String?,
  lastModified: (json['lastModified'] as num?)?.toInt() ?? 0,
  nodeStatus:
      $enumDecodeNullable(_$NodeStatusEnumMap, json['nodeStatus']) ??
      NodeStatus.normal,
  workId: (json['workId'] as num?)?.toInt(),
  source: $enumDecode(_$NodeSourceEnumMap, json['source']),
);

Map<String, dynamic> _$FileNodeToJson(_FileNode instance) => <String, dynamic>{
  'type': _$NodeTypeEnumMap[instance.type]!,
  'title': instance.title,
  'children': instance.children,
  'hash': instance.hash,
  'mediaStreamUrl': instance.mediaStreamUrl,
  'mediaDownloadUrl': instance.mediaDownloadUrl,
  'duration': instance.duration,
  'size': instance.size,
  'workTitle': instance.workTitle,
  'artist': instance.artist,
  'lastModified': instance.lastModified,
  'nodeStatus': _$NodeStatusEnumMap[instance.nodeStatus]!,
  'workId': instance.workId,
  'source': _$NodeSourceEnumMap[instance.source]!,
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

const _$NodeStatusEnumMap = {
  NodeStatus.normal: 'normal',
  NodeStatus.pending: 'pending',
  NodeStatus.parsing: 'parsing',
  NodeStatus.parsed: 'parsed',
};

const _$NodeSourceEnumMap = {
  NodeSource.asmrServer: 'asmrServer',
  NodeSource.localWork: 'localWork',
  NodeSource.localSingle: 'localSingle',
  NodeSource.cloudDrive: 'cloudDrive',
};
