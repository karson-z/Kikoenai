// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'] as String,
      type: json['type'] as String?,
      uid: (json['uid'] as num?)?.toInt(),
      nickname: json['nikeName'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'type': instance.type,
      'uid': instance.uid,
      'nikeName': instance.nickname,
      'phone': instance.phone,
    };
