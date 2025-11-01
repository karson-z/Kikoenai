import 'package:name_app/core/domain/result.dart';
import 'package:name_app/core/domain/errors.dart';
import 'package:dio/dio.dart';
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
          // 使用 _start + _limit，避免对 /users 使用 _page 造成 403
          if (start != null) '_start': start,
          if (limit != null) '_limit': limit,
        },
      );
      final List data = res.data as List;
      final users = data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(users);
    } catch (e) {
      // 当外部接口返回 403 或网络异常时，使用本地回退数据以保证演示分页可用
      if (e is DioException) {
        final s = start ?? 0;
        final l = limit ?? 10;
        const total = 50; // 本地回退总数
        final items = <UserModel>[];
        for (int i = 0; i < l; i++) {
          final id = s + i + 1;
          if (id > total) break;
          items.add(UserModel(id: id, name: 'User $id', email: 'user$id@example.com'));
        }
        return Result.success(items);
      }
      return Result.failure(mapException(e));
    }
  }
}