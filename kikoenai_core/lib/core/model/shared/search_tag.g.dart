// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_tag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SearchTagAdapter extends TypeAdapter<SearchTag> {
  @override
  final typeId = 16;

  @override
  SearchTag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SearchTag(
      fields[0] as String,
      fields[1] as String,
      fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SearchTag obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isExclude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchTagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
