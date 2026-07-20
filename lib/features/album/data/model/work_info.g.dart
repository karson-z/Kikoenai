// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkInfoAdapter extends TypeAdapter<WorkInfo> {
  @override
  final typeId = 12;

  @override
  WorkInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkInfo(
      id: (fields[0] as num).toInt(),
      sourceType: fields[1] as String?,
      sourceId: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceType)
      ..writeByte(2)
      ..write(obj.sourceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkInfo _$WorkInfoFromJson(Map<String, dynamic> json) => _WorkInfo(
  id: (json['id'] as num).toInt(),
  sourceType: json['source_type'] as String?,
  sourceId: json['source_id'] as String?,
);

Map<String, dynamic> _$WorkInfoToJson(_WorkInfo instance) => <String, dynamic>{
  'id': instance.id,
  'source_type': instance.sourceType,
  'source_id': instance.sourceId,
};
