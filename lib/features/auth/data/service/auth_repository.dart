import 'package:dio/dio.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/core/common/errors.dart';
import 'package:name_app/core/common/shared_preferences_service.dart';
import 'package:name_app/features/auth/data/model/login_params.dart';
import 'package:name_app/features/auth/data/model/login_response.dart';
import '../../../../core/utils/network/api_client.dart';

abstract class AuthRepository {
  Future<Result<LoginResponse>> login(LoginParams loginParams);
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SharedPreferencesService sharedPreferencesService;
  AuthRepositoryImpl(this.apiClient, this.sharedPreferencesService);
  @override
  Future<Result<LoginResponse>> login(LoginParams loginParams) async {
    try {
      final res = await apiClient.post<LoginResponse>(
        '/user/login',
        data: {
          'account': loginParams.account,
          'pwd': loginParams.pwd,
        },
        fromJson: (data) => LoginResponse.fromJson(data),
      );
      return res;
    } on DioException catch (e) {
      return Result.failure(
        error: ServerFailure(e.message ?? '网络错误'),
        code: e.response?.statusCode ?? 500,
        message: '${e.message} - 请求失败',
      );
    } catch (e) {
      final failure = mapException(e);
      return Result.failure(
        error: failure,
        code: failure.code,
        message: failure.message,
      );
    }
  }
}
