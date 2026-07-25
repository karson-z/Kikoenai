// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 31;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: (fields[0] as num?)?.toInt(),
      name: fields[1] as String,
      password: fields[2] as String?,
      token: fields[3] as String?,
      lastUpdateTime: fields[4] as DateTime?,
      loggedIn: fields[5] == null ? false : fields[5] as bool,
      group: fields[6] as String?,
      email: fields[7] as String?,
      recommenderUuid: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.token)
      ..writeByte(4)
      ..write(obj.lastUpdateTime)
      ..writeByte(5)
      ..write(obj.loggedIn)
      ..writeByte(6)
      ..write(obj.group)
      ..writeByte(7)
      ..write(obj.email)
      ..writeByte(8)
      ..write(obj.recommenderUuid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
