import 'package:flutter_test/flutter_test.dart';
import 'package:name_app/core/utils/network/api_client.dart';
import 'package:name_app/features/author/data/service/author_repository.dart';

void main() {
  group('Author 直接调用测试', () {
    late AuthorRepository repository;
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient.create();

      repository = AuthorRepositoryImpl(apiClient);
    });

    test('直接调用 getTag 方法获取标签数据', () async {
      // 直接调用repository的方法
      final result = await repository.getAuthor();

      // 打印结果以便查看
      print('\n=== 测试结果 ===');
      print('是否成功: ${result.isSuccess}');
      print('状态码: ${result.code}');
      print('消息: ${result.message}');

      if (result.isSuccess && result.data != null) {
        final pageResult = result.data!;
        print(pageResult[1].toJson());
        // 打印前几条标签数据
      }

      // 注意：如果API不可访问，这个测试会失败
      // 这里不添加断言，只是为了查看实际返回的数据
    });
  });
}
