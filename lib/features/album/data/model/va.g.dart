// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'va.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VAAdapter extends TypeAdapter<VA> {
  @override
  final typeId = 103;

  @override
  VA read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VA(
      id: fields[0] as String?,
      name: fields[1] as String?,
      count: (fields[2] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, VA obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VAAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VA _$VAFromJson(Map<String, dynamic> json) => _VA(
  id: json['id'] as String?,
  name: json['name'] as String?,
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$VAToJson(_VA instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'count': instance.count,
};
