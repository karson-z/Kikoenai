import 'package:dio/dio.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/core/common/errors.dart';
import 'package:name_app/features/author/data/model/author.dart';
import '../../../../core/utils/network/api_client.dart';

abstract class AuthorRepository {
  Future<Result<List<Author>>> getAuthor();
}

class AuthorRepositoryImpl implements AuthorRepository {
  final ApiClient apiClient;
  AuthorRepositoryImpl(this.apiClient);

  @override
  Future<Result<List<Author>>> getAuthor() async {
    try {
      final res = await apiClient.get<List<Author>>(
        '/author/list',
        fromJson: (data) => (data as List)
            .map((e) => Author.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      return Result.success(
        data: res.data ?? [],
        code: res.code ?? 200,
        message: res.message ?? '获取作者列表成功',
      );
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
