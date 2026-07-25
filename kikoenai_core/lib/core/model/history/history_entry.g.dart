// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final typeId = 32;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      session: fields[6] as PlaybackSession,
      lastItemId: fields[7] as String,
      lastPlayTime: (fields[8] as num).toInt(),
      lastProgressMs: (fields[9] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(6)
      ..write(obj.session)
      ..writeByte(7)
      ..write(obj.lastItemId)
      ..writeByte(8)
      ..write(obj.lastPlayTime)
      ..writeByte(9)
      ..write(obj.lastProgressMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
