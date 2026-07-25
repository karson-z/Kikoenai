// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaybackItemAdapter extends TypeAdapter<PlaybackItem> {
  @override
  final typeId = 54;

  @override
  PlaybackItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaybackItem(
      id: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      isVideo: fields[3] == null ? false : fields[3] as bool,
      source: fields[4] == null
          ? NodeSource.asmrServer
          : fields[4] as NodeSource,
      scopeId: fields[5] as String,
      workId: (fields[6] as num?)?.toInt(),
      albumTitle: fields[7] as String?,
      artist: fields[8] as String?,
      coverUrl: fields[9] as String?,
      smallCoverUrl: fields[10] as String?,
      durationMs: (fields[11] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.isVideo)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.scopeId)
      ..writeByte(6)
      ..write(obj.workId)
      ..writeByte(7)
      ..write(obj.albumTitle)
      ..writeByte(8)
      ..write(obj.artist)
      ..writeByte(9)
      ..write(obj.coverUrl)
      ..writeByte(10)
      ..write(obj.smallCoverUrl)
      ..writeByte(11)
      ..write(obj.durationMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaybackSessionAdapter extends TypeAdapter<PlaybackSession> {
  @override
  final typeId = 55;

  @override
  PlaybackSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaybackSession(
      id: fields[0] as String,
      currentIndex: fields[1] == null ? 0 : (fields[1] as num).toInt(),
      queue: fields[2] == null ? [] : (fields[2] as List).cast<PlaybackItem>(),
      createdAt: (fields[3] as num).toInt(),
      updatedAt: (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.currentIndex)
      ..writeByte(2)
      ..write(obj.queue)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
