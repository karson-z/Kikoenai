// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CircleAdapter extends TypeAdapter<Circle> {
  @override
  final typeId = 100;

  @override
  Circle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Circle(
      id: (fields[0] as num?)?.toInt(),
      name: fields[1] as String?,
      sourceId: fields[2] as String?,
      sourceType: fields[3] as String?,
      count: (fields[4] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Circle obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sourceId)
      ..writeByte(3)
      ..write(obj.sourceType)
      ..writeByte(4)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Circle _$CircleFromJson(Map<String, dynamic> json) => _Circle(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  sourceId: json['source_id'] as String?,
  sourceType: json['source_type'] as String?,
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$CircleToJson(_Circle instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'source_id': instance.sourceId,
  'source_type': instance.sourceType,
  'count': instance.count,
};
