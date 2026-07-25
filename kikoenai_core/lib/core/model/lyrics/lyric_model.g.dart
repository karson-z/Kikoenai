// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyric_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyricConfigModelAdapter extends TypeAdapter<LyricConfigModel> {
  @override
  final typeId = 70;

  @override
  LyricConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricConfigModel(
      mainFontSize: fields[0] == null ? 18.0 : (fields[0] as num).toDouble(),
      transFontSize: fields[1] == null ? 12.0 : (fields[1] as num).toDouble(),
      activeFontSize: fields[2] == null ? 22.0 : (fields[2] as num).toDouble(),
      lineGap: fields[3] == null ? 35.0 : (fields[3] as num).toDouble(),
      translationGap: fields[4] == null ? 5.0 : (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, LyricConfigModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.mainFontSize)
      ..writeByte(1)
      ..write(obj.transFontSize)
      ..writeByte(2)
      ..write(obj.activeFontSize)
      ..writeByte(3)
      ..write(obj.lineGap)
      ..writeByte(4)
      ..write(obj.translationGap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
