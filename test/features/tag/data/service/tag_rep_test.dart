import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:name_app/core/utils/network/api_client.dart';
import 'package:name_app/features/tag/data/service/tag_repository.dart';

void main() {
  group('TagRepository 直接调用测试', () {
    late TagRepository repository;
    late ApiClient apiClient;

    setUp(() {
      // 创建实际的Dio实例和ApiClient
      // 注意：这里使用实际配置，但可能需要根据实际环境调整
      final dio = Dio(BaseOptions(
        baseUrl: 'http://127.0.0.1:8081/api', // 请确保这个地址是可访问的
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': '39677bf7-c426-474f-9b59-8063f424048a', // 如果有 token 可动态替换
          'X-Request-Source': 'flutter-app', // 例如添加自定义标识
        },
      ));

      // 添加日志拦截器以便查看请求详情
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));

      apiClient = ApiClient(dio);
      repository = TagRepositoryImpl(apiClient);
    });

    test('直接调用 getTag 方法获取标签数据', () async {
      // 直接调用repository的方法
      final result = await repository.getTag();

      // 打印结果以便查看
      print('\n=== 测试结果 ===');
      print('是否成功: ${result.isSuccess}');
      print('状态码: ${result.code}');
      print('消息: ${result.message}');

      if (result.isSuccess && result.data != null) {
        final pageResult = result.data!;
        print('\n分页信息:');
        print('- 总记录数: ${pageResult.total}');
        print('- 当前页码: ${pageResult.current}');
        print('- 每页大小: ${pageResult.size}');
        print('- 总页数: ${pageResult.pages}');
        print('- 当前页记录数: ${pageResult.records.length}');
        print('- 是否有下一页: ${pageResult.hasNextPage}');

        // 打印前几条标签数据
        print('\n前5条标签数据:');
        for (var i = 0; i < pageResult.records.length && i < 5; i++) {
          final tag = pageResult.records[i];
          print(
              '[$i] ID: ${tag.id}, 名称: ${tag.name}, 数量: ${tag.num}, 创建时间: ${tag.createdAt}');
          print('    点赞: ${tag.isLike}, 点踩: ${tag.isDisLike}');
        }
      } else if (!result.isSuccess && result.error != null) {
        print('\n错误信息:');
        print('- 错误类型: ${result.error.runtimeType}');
        print('- 错误详情: ${result.error}');
      }

      // 注意：如果API不可访问，这个测试会失败
      // 这里不添加断言，只是为了查看实际返回的数据
    });

    test('使用自定义参数调用 getTag 方法', () async {
      // 使用自定义分页参数
      final result = await repository.getTag(page: 1, size: 5);

      // 打印结果
      print('\n=== 自定义参数测试结果 ===');
      print('是否成功: ${result.isSuccess}');
      print('状态码: ${result.code}');
      print('消息: ${result.message}');

      if (result.isSuccess && result.data != null) {
        final pageResult = result.data!;
        print('\n分页信息 (size=5):');
        print('- 每页大小: ${pageResult.size}');
        print('- 当前页记录数: ${pageResult.records.length}');
      }
    });
    test('使用自定义参数调用 getTag 方法', () async {
      // 使用自定义分页参数
      final result = await repository.getTagByAlbumId(394, 37);

      // 打印结果
      print('\n=== 自定义参数测试结果 ===');
      print('是否成功: ${result.isSuccess}');
      print('状态码: ${result.code}');
      print('消息: ${result.message}');

      if (result.isSuccess && result.data != null) {
        final tag = result.data!;
        print('- 标签信息: ${tag.toJson()}');
      }
    });
  });
}
