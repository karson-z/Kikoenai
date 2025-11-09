// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: (json['uid'] as num).toInt(),
      nickname: json['nickname'] as String,
      account: json['account'] as String?,
      realName: json['realName'] as String?,
      birthday: json['birthday'] as String?,
      cardId: json['cardId'] as String?,
      mark: json['mark'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      addIp: json['addIp'] as String?,
      lastIp: json['lastIp'] as String?,
      lastLoginTime: json['lastLoginTime'] == null
          ? null
          : DateTime.parse(json['lastLoginTime'] as String),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.uid,
      'nickname': instance.nickname,
      'account': instance.account,
      'realName': instance.realName,
      'birthday': instance.birthday,
      'cardId': instance.cardId,
      'mark': instance.mark,
      'avatar': instance.avatar,
      'phone': instance.phone,
      'addIp': instance.addIp,
      'lastIp': instance.lastIp,
      'lastLoginTime': instance.lastLoginTime?.toIso8601String(),
    };
