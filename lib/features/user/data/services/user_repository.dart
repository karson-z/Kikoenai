import 'package:dio/dio.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/core/common/errors.dart';
import '../../../../core/utils/network/api_client.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<Result<UserModel>> getUsers();
}

class UserRepositoryImpl implements UserRepository {
  final ApiClient apiClient;
  UserRepositoryImpl(this.apiClient);

  @override
  Future<Result<UserModel>> getUsers() async {
    try {
      final res = await apiClient.get(
        '/user/info',
        fromJson: (data) => UserModel.fromJson(data),
      );
      // 成功返回，附上状态码与提示
      return res;
    } on DioException catch (e) {
      // Dio 网络错误分支
      return Result.failure(
        error: mapException(e),
        code: e.response?.statusCode ?? 403,
        message: '使用本地回退数据 (${e.message})',
      );
    }
  }
}
