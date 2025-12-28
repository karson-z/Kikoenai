import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/global_exception.dart';
import 'package:kikoenai/core/common/result.dart';
import 'package:kikoenai/features/auth/data/model/login_params.dart';
import '../../../../core/service/cache_service.dart';
import '../../../../core/utils/network/api_client.dart';
import '../model/auth_response.dart';
import '../model/register_model.dart';

abstract class AuthRepository {
  Future<Result<Map<String, dynamic>>> login(LoginParams loginParams);

  Future<Result<Map<String, dynamic>>> register(RegisterRequestModel reg);
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient api;

  AuthRepositoryImpl(this.api);

  /// 登录方法
  @override
  Future<Result<Map<String, dynamic>>> login(LoginParams loginParams) async {
    // 设置 host
    final response = await api.post<Map<String, dynamic>>(
      '/auth/me',
      data: {
        'name': loginParams.username,
        'password': loginParams.password,
      },
    );
    return response;
  }

  @override
  Future<Result<Map<String, dynamic>>> register(
      RegisterRequestModel reg) async {
    try {
      final uuid = await CacheService.instance.getOrGenerateRecommendUuid();

      final requestModelWithUuid = reg.copyWith(recommenderUuid: uuid);

      // 3. 发起请求
      final response = await api.post<Map<String, dynamic>>(
        '/auth/register',
        data: requestModelWithUuid.toJson(),
      );

      final Map<String, dynamic>? data = response.data;

      // 4. 【空安全检查】防止 data 为空导致 crash
      if (data == null) {
        throw GlobalException("注册失败");
      }

      // 5. 业务逻辑检查
      final authResponse = AuthResponse.fromJson(data);

      if (!authResponse.isSuccess) {
        // 【修复】不要 throw，而是返回 Result.failure
        // 这样 UI 层可以通过 result.isSuccess 判断，而不是被迫写 try-catch
        throw GlobalException(authResponse.error ?? "注册失败");
      }

      // 成功
      return Result.success(data: data);
    } catch (e) {
      throw GlobalException("注册失败");
    }
  }
}
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthRepositoryImpl(api);
});

