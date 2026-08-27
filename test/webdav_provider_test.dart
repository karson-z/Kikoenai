import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';

void main() {
  group('WebDavConnectionConfig', () {
    test('normalizes endpoint and root directory', () {
      final config = const WebDavConnectionConfig(
        serverUrl: ' https://cloud.example.com/dav ',
        username: ' kiko ',
        password: 'secret',
        rootPath: r'ASMR\Favorites/',
      ).validated();

      expect(config.serverUrl, 'https://cloud.example.com/dav/');
      expect(config.username, 'kiko');
      expect(config.rootPath, '/ASMR/Favorites');
      expect(config.password, 'secret');
    });

    test('rejects credentials embedded in the endpoint', () {
      expect(
        () => const WebDavConnectionConfig(
          serverUrl: 'https://user:secret@cloud.example.com/dav/',
          username: '',
          password: '',
          rootPath: '/',
        ).validated(),
        throwsFormatException,
      );
    });

    test('rejects parent traversal in the configured root', () {
      expect(
        () => const WebDavConnectionConfig(
          serverUrl: 'https://cloud.example.com/dav/',
          username: '',
          password: '',
          rootPath: '/../private',
        ).validated(),
        throwsFormatException,
      );
    });
  });

  test('buildFileUri encodes path without leaking credentials', () {
    final uri = WebDavController.buildFileUri(
      Uri.parse('https://cloud.example.com/remote.php/dav/files/kiko/'),
      '/ASMR/中文 音声.mp3',
    );

    expect(uri.userInfo, isEmpty);
    expect(uri.pathSegments, [
      'remote.php',
      'dav',
      'files',
      'kiko',
      'ASMR',
      '中文 音声.mp3',
    ]);
    expect(
      uri.toString(),
      contains('%E4%B8%AD%E6%96%87%20%E9%9F%B3%E5%A3%B0.mp3'),
    );
  });

  test('describeError returns an actionable authentication message', () {
    final request = RequestOptions(path: '/');
    final error = DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    expect(WebDavController.describeError(error), contains('认证失败'));
  });
}
