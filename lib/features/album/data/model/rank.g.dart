// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RankAdapter extends TypeAdapter<Rank> {
  @override
  final typeId = 101;

  @override
  Rank read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rank(
      term: fields[0] as String,
      category: fields[1] as String,
      rank: (fields[2] as num).toInt(),
      rankDate: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Rank obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.term)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.rank)
      ..writeByte(3)
      ..write(obj.rankDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rank _$RankFromJson(Map<String, dynamic> json) => _Rank(
  term: json['term'] as String,
  category: json['category'] as String,
  rank: (json['rank'] as num).toInt(),
  rankDate: json['rank_date'] as String,
);

Map<String, dynamic> _$RankToJson(_Rank instance) => <String, dynamic>{
  'term': instance.term,
  'category': instance.category,
  'rank': instance.rank,
  'rank_date': instance.rankDate,
};
