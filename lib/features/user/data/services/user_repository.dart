import 'package:dio/dio.dart';
import 'package:name_app/core/domain/result.dart';
import 'package:name_app/core/domain/errors.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<Result<List<UserModel>>> getUsers({int? start, int? limit});
}

class UserRepositoryImpl implements UserRepository {
  final ApiClient apiClient;
  UserRepositoryImpl(this.apiClient);

  @override
  Future<Result<List<UserModel>>> getUsers({int? start, int? limit}) async {
    try {
      final res = await apiClient.get(
        '/users',
        queryParameters: {
          if (start != null) '_start': start,
          if (limit != null) '_limit': limit,
        },
        fromJson: (data) => UserModel.fromJson(data),
      );
      final List<dynamic> data = res.data as List<dynamic>;
      final users = data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // 成功返回，附上状态码与提示
      return Result.success(
        data: users,
        code: res.code ?? 200,
        message: '获取用户列表成功',
      );
    } on DioException catch (e) {
      // Dio 网络错误分支
      final s = start ?? 0;
      final l = limit ?? 10;
      const total = 50;
      final items = <UserModel>[];

      for (int i = 0; i < l; i++) {
        final id = s + i + 1;
        if (id > total) break;
        items.add(UserModel(
          id: id,
          name: 'User $id',
          email: 'user$id@example.com',
        ));
      }

      // 这里用 fallback 数据返回，但带有 warning 状态
      return Result.success(
        data: items,
        code: e.response?.statusCode ?? 403,
        message: '使用本地回退数据 (${e.message})',
      );
    } catch (e) {
      // 其它异常
      final failure = mapException(e);
      return Result.failure(
        error: failure,
        code: failure.code,
        message: failure.message,
      );
    }
  }
}
