import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/global_exception.dart';
import 'package:kikoenai/features/auth/data/model/login_params.dart';
import '../../../../core/utils/network/api_client.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../model/auth_response.dart';
import '../model/register_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(LoginParams loginParams);

  Future<AuthResponse> register(RegisterRequestModel reg);
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient api;

  AuthRepositoryImpl(this.api);

  @override
  Future<AuthResponse> login(LoginParams loginParams) async {
    final response = await api.post<Map<String, dynamic>>(
      '/auth/me',
      data: {
        'name': loginParams.username,
        'password': loginParams.password,
      },
    );
    return _parseAuthResponse(response, fallbackMessage: '登录失败');
  }

  @override
  Future<AuthResponse> register(RegisterRequestModel reg) async {
    final uuid = await CacheService.instance.getOrGenerateRecommendUuid();
    final requestModelWithUuid = reg.copyWith(recommenderUuid: uuid);
    final response = await api.post<Map<String, dynamic>>(
      '/auth/register',
      data: requestModelWithUuid.toJson(),
    );
    return _parseAuthResponse(response, fallbackMessage: '注册失败');
  }

  AuthResponse _parseAuthResponse(
    Map<String, dynamic>? data, {
    required String fallbackMessage,
  }) {
    if (data == null) {
      throw GlobalException(fallbackMessage);
    }

    final authResponse = AuthResponse.fromJson(data);
    if (!authResponse.isSuccess) {
      throw GlobalException(authResponse.error ?? fallbackMessage);
    }
    return authResponse;
  }
}
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthRepositoryImpl(api);
});
