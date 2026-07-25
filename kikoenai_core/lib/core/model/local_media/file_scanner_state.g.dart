// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_scanner_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanTargetAdapter extends TypeAdapter<ScanTarget> {
  @override
  final typeId = 90;

  @override
  ScanTarget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanTarget(
      path: fields[0] as String,
      addedAt: (fields[1] as num).toInt(),
      lastScannedAt: (fields[2] as num?)?.toInt(),
      scanMode: fields[3] as ScanMode,
    );
  }

  @override
  void write(BinaryWriter writer, ScanTarget obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.addedAt)
      ..writeByte(2)
      ..write(obj.lastScannedAt)
      ..writeByte(3)
      ..write(obj.scanMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanTargetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanTarget _$ScanTargetFromJson(Map<String, dynamic> json) => _ScanTarget(
  path: json['path'] as String,
  addedAt: (json['addedAt'] as num).toInt(),
  lastScannedAt: (json['lastScannedAt'] as num?)?.toInt(),
  scanMode: $enumDecode(_$ScanModeEnumMap, json['scanMode']),
);

Map<String, dynamic> _$ScanTargetToJson(_ScanTarget instance) =>
    <String, dynamic>{
      'path': instance.path,
      'addedAt': instance.addedAt,
      'lastScannedAt': instance.lastScannedAt,
      'scanMode': _$ScanModeEnumMap[instance.scanMode]!,
    };

const _$ScanModeEnumMap = {
  ScanMode.audio: 'audio',
  ScanMode.video: 'video',
  ScanMode.subtitles: 'subtitles',
};
