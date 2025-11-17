import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/features/auth/data/model/login_params.dart';
import '../../../../core/utils/network/api_client.dart';

abstract class AuthRepository {
  Future<Result<Map<String, dynamic>>> login(LoginParams loginParams);
}

class AuthRepositoryImpl implements AuthRepository{
  final ApiClient api;

  AuthRepositoryImpl(this.api);

  /// 登录方法
  @override
  Future<Result<Map<String, dynamic>>> login(LoginParams loginParams) async {
    // 设置 host
    final response = await api.post(
      '/auth/me',
      data: {
        'name': loginParams.username,
        'password': loginParams.password,
      },
    );
    return response;
  }
}
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthRepositoryImpl(api);
});

