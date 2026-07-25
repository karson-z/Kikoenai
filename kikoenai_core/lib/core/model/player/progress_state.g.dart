// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgressBarStateAdapter extends TypeAdapter<ProgressBarState> {
  @override
  final typeId = 51;

  @override
  ProgressBarState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressBarState(
      current: fields[0] as Duration,
      buffered: fields[1] as Duration,
      total: fields[2] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressBarState obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.current)
      ..writeByte(1)
      ..write(obj.buffered)
      ..writeByte(2)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressBarStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
