// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'other_language_edition.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OtherLanguageEditionAdapter extends TypeAdapter<OtherLanguageEdition> {
  @override
  final typeId = 105;

  @override
  OtherLanguageEdition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OtherLanguageEdition(
      id: (fields[0] as num?)?.toInt(),
      lang: fields[1] as String?,
      title: fields[2] as String?,
      sourceId: fields[3] as String?,
      isOriginal: fields[4] as bool?,
      sourceType: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OtherLanguageEdition obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lang)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.sourceId)
      ..writeByte(4)
      ..write(obj.isOriginal)
      ..writeByte(5)
      ..write(obj.sourceType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtherLanguageEditionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtherLanguageEdition _$OtherLanguageEditionFromJson(
  Map<String, dynamic> json,
) => _OtherLanguageEdition(
  id: (json['id'] as num?)?.toInt(),
  lang: json['lang'] as String?,
  title: json['title'] as String?,
  sourceId: json['source_id'] as String?,
  isOriginal: json['is_original'] as bool?,
  sourceType: json['source_type'] as String?,
);

Map<String, dynamic> _$OtherLanguageEditionToJson(
  _OtherLanguageEdition instance,
) => <String, dynamic>{
  'id': instance.id,
  'lang': instance.lang,
  'title': instance.title,
  'source_id': instance.sourceId,
  'is_original': instance.isOriginal,
  'source_type': instance.sourceType,
};
