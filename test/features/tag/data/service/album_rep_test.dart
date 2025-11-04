import 'package:flutter_test/flutter_test.dart';
import 'package:name_app/core/network/api_client.dart';
import 'package:name_app/features/album/data/service/album_repository.dart';

void main() {
  group('Album 直接调用测试', () {
    late AlbumRepository repository;
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient.create(
        tokenProvider: () async => '39677bf7-c426-474f-9b59-8063f424048a',
      );

      repository = AlbumRepositoryImpl(apiClient);
    });

    test('直接调用 getAlbum 方法获取标签数据', () async {
      // 直接调用repository的方法
      final result = await repository.getAlbumPageList();

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
          final album = pageResult.records[i];
          print(
              '[$i] ID: ${album.id}, 名称: ${album.albumTitle}, 数量: ${album.ageRating}, 创建时间: ${album.createdAt}');
          print('    点赞: ${album.coverUrl}, 点踩: ${album.rjCode}');
        }
      }

      // 注意：如果API不可访问，这个测试会失败
      // 这里不添加断言，只是为了查看实际返回的数据
    });
  });
}
