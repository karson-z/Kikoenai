import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  /// 用户id
  @JsonKey(name: 'uid')
  final int uid;
  
  /// 用户昵称
  @JsonKey(name: 'nickname')
  final String nickname;
  
  /// 用户账号
  @JsonKey(name: 'account')
  final String? account;
  
  /// 真实姓名
  @JsonKey(name: 'realName')
  final String? realName;
  
  /// 生日
  @JsonKey(name: 'birthday')
  final String? birthday;
  
  /// 身份证号码
  @JsonKey(name: 'cardId')
  final String? cardId;
  
  /// 用户备注
  @JsonKey(name: 'mark')
  final String? mark;
  
  /// 用户头像
  @JsonKey(name: 'avatar')
  final String? avatar;
  
  /// 手机号码
  @JsonKey(name: 'phone')
  final String? phone;
  
  /// 添加ip
  @JsonKey(name: 'addIp')
  final String? addIp;
  
  /// 最后一次登录ip
  @JsonKey(name: 'lastIp')
  final String? lastIp;
  
  /// 最后一次登录时间
  @JsonKey(name: 'lastLoginTime')
  final DateTime? lastLoginTime;

  const UserModel({
    required this.uid,
    required this.nickname,
    this.account,
    this.realName,
    this.birthday,
    this.cardId,
    this.mark,
    this.avatar,
    this.phone,
    this.addIp,
    this.lastIp,
    this.lastLoginTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  String toString() {
    return 'UserModel{uid: $uid, nickname: $nickname, account: ${account ?? 'null'}, ' 'realName: ${realName ?? 'null'}, birthday: ${birthday ?? 'null'}, ' 'cardId: ${cardId ?? 'null'}, mark: ${mark ?? 'null'}, ' 'avatar: ${avatar ?? 'null'}, phone: ${phone ?? 'null'}, ' 'addIp: ${addIp ?? 'null'}, lastIp: ${lastIp ?? 'null'}, ' 'lastLoginTime: ${lastLoginTime ?? 'null'}}';
  }
}