// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthResponseAdapter extends TypeAdapter<AuthResponse> {
  @override
  final typeId = 30;

  @override
  AuthResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthResponse(
      user: fields[0] as User?,
      token: fields[1] as String?,
      error: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AuthResponse obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.user)
      ..writeByte(1)
      ..write(obj.token)
      ..writeByte(2)
      ..write(obj.error);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
