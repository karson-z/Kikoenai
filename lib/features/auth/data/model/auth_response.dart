import 'package:kikoenai/features/user/data/models/user.dart';

class AuthResponse {
  final User? user;
  final String? token;
  final String? error;

  const AuthResponse({
    this.user,
    this.token,
    this.error,
  });

  /// 核心逻辑：判断是否成功
  /// 规则：没有 error 且 token 不为空即为成功
  bool get isSuccess => error == null && token != null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      // 如果 json 中包含 'user' 且不为 null，则解析 User
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,

      token: json['token'] as String?,

      // 错误信息字段
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toJson(),
      if (token != null) 'token': token,
      if (error != null) 'error': error,
    };
  }
}