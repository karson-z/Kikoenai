// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanModeAdapter extends TypeAdapter<ScanMode> {
  @override
  final typeId = 91;

  @override
  ScanMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScanMode.audio;
      case 1:
        return ScanMode.video;
      case 2:
        return ScanMode.subtitles;
      default:
        return ScanMode.audio;
    }
  }

  @override
  void write(BinaryWriter writer, ScanMode obj) {
    switch (obj) {
      case ScanMode.audio:
        writer.writeByte(0);
      case ScanMode.video:
        writer.writeByte(1);
      case ScanMode.subtitles:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
