import 'package:dio/dio.dart';
import 'package:name_app/core/domain/page_result.dart';
import 'package:name_app/core/domain/result.dart';
import 'package:name_app/core/domain/errors.dart';
import 'package:name_app/features/album/data/model/album_res.dart';
import '../../../../core/network/api_client.dart';

abstract class AlbumRepository {
  Future<Result<PageResult<AlbumResponse>>> getAlbumPageList({
    int? start,
    int? limit,
  });
}

class AlbumRepositoryImpl implements AlbumRepository {
  final ApiClient apiClient;
  AlbumRepositoryImpl(this.apiClient);
  @override
  Future<Result<PageResult<AlbumResponse>>> getAlbumPageList({
    int? start,
    int? limit,
  }) async {
    try {
      final res = await apiClient.post<PageResult<AlbumResponse>>(
        '/album/list',
        data: {
          'current': start ?? 1,
          'size': limit ?? 10,
        },
        fromJson: (data) => PageResult<AlbumResponse>.fromJson(
          data,
          (item) => AlbumResponse.fromJson(item as Map<String, dynamic>),
        ),
      );

      return Result.success(
        data: res.data!,
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
