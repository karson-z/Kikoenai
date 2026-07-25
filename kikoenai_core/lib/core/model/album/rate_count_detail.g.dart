// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_count_detail.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RateCountDetailAdapter extends TypeAdapter<RateCountDetail> {
  @override
  final typeId = 104;

  @override
  RateCountDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RateCountDetail(
      reviewPoint: (fields[0] as num).toInt(),
      count: (fields[1] as num).toInt(),
      ratio: (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, RateCountDetail obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.reviewPoint)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.ratio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateCountDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RateCountDetail _$RateCountDetailFromJson(Map<String, dynamic> json) =>
    _RateCountDetail(
      reviewPoint: (json['review_point'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      ratio: (json['ratio'] as num).toInt(),
    );

Map<String, dynamic> _$RateCountDetailToJson(_RateCountDetail instance) =>
    <String, dynamic>{
      'review_point': instance.reviewPoint,
      'count': instance.count,
      'ratio': instance.ratio,
    };
