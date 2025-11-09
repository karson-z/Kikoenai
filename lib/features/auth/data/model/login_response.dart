import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

/// 用户登录返回数据
@JsonSerializable()
class LoginResponse {
  /// 用户登录密钥
  String token;

  /// 状态: login-登录, register-注册, start-注册起始页
  String? type;

  /// 登录用户Uid
  int? uid;

  /// 登录用户昵称
  @JsonKey(name: 'nikeName')
  String? nickname;

  /// 登录用户手机号
  String? phone;

  LoginResponse({
    required this.token,
    this.type,
    this.uid,
    this.nickname,
    this.phone,
  });

  /// 将json数据转换为LoginResponse对象
  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  /// 将LoginResponse对象转换为json数据
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  @override
  String toString() {
    return 'LoginResponse{token: $token, type: ${type ?? 'null'}, uid: ${uid ?? 'null'}, nickname: ${nickname ?? 'null'}, phone: ${phone ?? 'null'}}';
  }
}

/// 登录类型枚举
enum LoginType {
  login,
  register,
  start,
}