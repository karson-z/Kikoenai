import 'package:json_annotation/json_annotation.dart';

part 'login_params.g.dart';

/// 登录参数模型
/// 对应TypeScript接口：
/// interface LoginParams { 
///   account: string 
///   pwd: string 
/// }
@JsonSerializable()
class LoginParams {
  final String username;
  final String password;

  LoginParams({required this.username, required this.password});

  factory LoginParams.fromJson(Map<String, dynamic> json) =>
      _$LoginParamsFromJson(json);

  Map<String, dynamic> toJson() => _$LoginParamsToJson(this);
}