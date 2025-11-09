import 'package:dio/dio.dart';
import 'package:name_app/core/common/page_result.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/core/common/errors.dart';
import '../../../../core/utils/network/api_client.dart';
import 'package:name_app/features/tag/data/model/tag.dart'; // 使用包路径导入

abstract class TagRepository {
  /// 获取标签列表
  /// [page] 当前页码，默认值为 1
  /// [size] 每页数量，默认值为 20
  Future<Result<PageResult<Tag>>> getTag({int page = 1, int size = 20});

  /// 根据专辑ID + 标签Id 获取标签基本信息
  /// [TagId,albumId] 专辑ID,标签ID
  Future<Result<Tag>> getTagByAlbumId(int albumId, int tagId);
}

class TagRepositoryImpl implements TagRepository {
  final ApiClient apiClient;
  TagRepositoryImpl(this.apiClient);

  @override
  Future<Result<PageResult<Tag>>> getTag({int page = 1, int size = 20}) async {
    try {
      final res = await apiClient.get(
        '/tag/list',
        queryParameters: {
          'current': page,
          'size': size,
        },
        fromJson: (json) => PageResult<Tag>.fromJson(
            json, (json) => Tag.fromJson(json as Map<String, dynamic>)),
      );
      final pageInfo = res.data!;
      // 成功返回，附上状态码与提示
      return Result.success(
        data: pageInfo,
        code: res.code ?? 200,
        message: res.message ?? '获取标签列表成功',
      );
    } on DioException catch (e) {
      // Dio 网络错误分支

      // 这里用 fallback 数据返回，但带有 warning 状态
      return Result.failure(
        error: ServerFailure(e.message ?? 'Unknown error'),
        code: e.response?.statusCode ?? 403,
        message: '${e.message} - 请求失败',
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

  @override
  Future<Result<Tag>> getTagByAlbumId(int albumId, int tagId) async {
    try {
      final res = await apiClient.get(
        '/tag/getTagStat/$albumId/$tagId',
        fromJson: (json) => Tag.fromJson(json as Map<String, dynamic>),
      );
      final pageInfo = res.data!;
      // 成功返回，附上状态码与提示
      return Result.success(
        data: pageInfo,
        code: res.code ?? 200,
        message: res.message ?? '获取标签信息成功',
      );
    } on DioException catch (e) {
      // Dio 网络错误分支
      // 这里用 fallback 数据返回，但带有 warning 状态
      return Result.failure(
        error: ServerFailure(e.message ?? 'Unknown error'),
        code: e.response?.statusCode ?? 403,
        message: '${e.message} - 请求失败',
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
