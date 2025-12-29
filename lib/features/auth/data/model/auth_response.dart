
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/features/user/data/models/user.dart';

// 这一行必须加，文件名必须和当前文件名一致
part 'auth_response.g.dart';

@HiveType(typeId: 9) // 设置唯一的 TypeId
class AuthResponse {

  @HiveField(0) // 字段索引，一旦定好不要轻易修改
  final User? user;

  @HiveField(1)
  final String? token;

  @HiveField(2)
  final String? error;

  const AuthResponse({
    this.user,
    this.token,
    this.error,
  });

  bool get isSuccess => error == null && token != null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      token: json['token'] as String?,
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