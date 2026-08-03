import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/network/cookie_manager.dart';
import 'package:kikoenai_sites/network/exception.dart';
import 'package:kikoenai_sites/network/http_client.dart';
import 'package:kikoenai_sites/network/request_config.dart';

/// 简易 Mock HTTP Adapter
///
/// 注册 [handler] 回调，按 path 匹配返回模拟响应。
class MockAdapter implements HttpClientAdapter {
  final Map<String, _MockHandler> _handlers = {};

  void register(String path, _MockHandler handler) {
    _handlers[path] = handler;
  }

  void registerGet(
    String path,
    Map<String, dynamic> response, {
    int status = 200,
  }) {
    register(path, (options) => _jsonResponse(response, status));
  }

  void registerPost(
    String path,
    Map<String, dynamic> response, {
    int status = 200,
  }) {
    register(path, (options) => _jsonResponse(response, status));
  }

  void registerError(String path, int status, {Map<String, dynamic>? data}) {
    register(path, (options) => _jsonResponse(data ?? {}, status));
  }

  ResponseBody _jsonResponse(Map<String, dynamic> data, int status) {
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    // 匹配精确路径
    if (_handlers.containsKey(path)) {
      return _handlers[path]!(options);
    }
    // 匹配带前缀（例如 baseUrl + path）
    for (final entry in _handlers.entries) {
      if (path.endsWith(entry.key)) {
        return entry.value(options);
      }
    }
    // 未匹配，返回 404
    return ResponseBody.fromString(
      'Not Found',
      404,
      headers: {
        Headers.contentTypeHeader: ['text/plain'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

typedef _MockHandler = ResponseBody Function(RequestOptions options);

void main() {
  late MockAdapter mockAdapter;
  late SitesHttpClient client;

  setUp(() {
    mockAdapter = MockAdapter();
    final cookieManager = SitesCookieManager();
    client = SitesHttpClient(
      config: const RequestConfig(
        baseUrl: 'https://test.example.com',
        enableLogger: false,
      ),
      cookieManager: cookieManager,
      tokenProvider: () async => 'test-token',
    );
    client.dio.httpClientAdapter = mockAdapter;
  });

  tearDown(() {
    client.close();
  });

  group('SitesHttpClient', () {
    test('get 请求成功返回数据', () async {
      mockAdapter.registerGet('/api/data', {'code': 0, 'msg': 'ok'});

      final result = await client.get<Map<String, dynamic>>('/api/data');

      expect(result['code'], 0);
      expect(result['msg'], 'ok');
    });

    test('post 请求成功返回数据', () async {
      mockAdapter.registerPost('/api/login', {'token': 'abc123'});

      final result = await client.post<Map<String, dynamic>>(
        '/api/login',
        data: {'username': 'test', 'password': '123'},
      );

      expect(result['token'], 'abc123');
    });

    test('put 请求成功返回数据', () async {
      mockAdapter.register('/api/update', (options) {
        return ResponseBody.fromString(
          jsonEncode({'updated': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final result = await client.put<Map<String, dynamic>>(
        '/api/update',
        data: {'name': 'new'},
      );

      expect(result['updated'], true);
    });

    test('delete 请求成功返回数据', () async {
      mockAdapter.register('/api/delete', (options) {
        return ResponseBody.fromString(
          jsonEncode({'deleted': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final result = await client.delete<Map<String, dynamic>>('/api/delete');

      expect(result['deleted'], true);
    });

    test('401 错误抛出 unauthorized 异常', () async {
      mockAdapter.registerError('/api/secret', 401, data: {'code': 401});

      expect(
        () => client.get<Map<String, dynamic>>('/api/secret'),
        throwsA(
          isA<SitesNetworkException>().having(
            (e) => e.code,
            'code',
            SitesExceptionCode.unauthorized,
          ),
        ),
      );
    });

    test('404 错误抛出 notFound 异常', () async {
      mockAdapter.registerError('/api/missing', 404);

      expect(
        () => client.get<Map<String, dynamic>>('/api/missing'),
        throwsA(
          isA<SitesNetworkException>().having(
            (e) => e.code,
            'code',
            SitesExceptionCode.notFound,
          ),
        ),
      );
    });

    test('500 错误抛出 serverError 异常', () async {
      mockAdapter.registerError('/api/crash', 500);

      expect(
        () => client.get<Map<String, dynamic>>('/api/crash'),
        throwsA(
          isA<SitesNetworkException>().having(
            (e) => e.code,
            'code',
            SitesExceptionCode.serverError,
          ),
        ),
      );
    });

    test('相对路径 GET 在服务器恢复后只重试一次', () async {
      var requestCount = 0;
      var recoveryCount = 0;
      final recoveringClient = SitesHttpClient(
        config: const RequestConfig(
          baseUrl: 'https://test.example.com',
          enableLogger: false,
        ),
        readRequestRecovery: (exception) async {
          recoveryCount++;
          return const ReadRecoveryResult.recovered();
        },
      );
      addTearDown(recoveringClient.close);
      recoveringClient.dio.httpClientAdapter = mockAdapter;
      mockAdapter.register('/api/retry', (options) {
        requestCount++;
        return requestCount == 1
            ? mockAdapter._jsonResponse({}, 503)
            : mockAdapter._jsonResponse({'ok': true}, 200);
      });

      final result = await recoveringClient.get<Map<String, dynamic>>(
        '/api/retry',
      );

      expect(result['ok'], isTrue);
      expect(requestCount, 2);
      expect(recoveryCount, 1);
    });

    test('全部服务器不可用时抛出专用异常并保留站点上下文', () async {
      var requestCount = 0;
      final recoveringClient = SitesHttpClient(
        config: const RequestConfig(
          baseUrl: 'https://test.example.com',
          enableLogger: false,
        ),
        readRequestRecovery: (exception) async {
          return const ReadRecoveryResult.allServersUnavailable(
            context: {
              'siteId': 'site.test',
              'serverIds': ['primary', 'backup'],
            },
          );
        },
      );
      addTearDown(recoveringClient.close);
      recoveringClient.dio.httpClientAdapter = mockAdapter;
      mockAdapter.register('/api/unavailable', (options) {
        requestCount++;
        return mockAdapter._jsonResponse({}, 503);
      });

      await expectLater(
        recoveringClient.get<Map<String, dynamic>>('/api/unavailable'),
        throwsA(
          isA<SitesNetworkException>()
              .having(
                (error) => error.code,
                'code',
                SitesExceptionCode.allServersUnavailable,
              )
              .having(
                (error) => error.context?['siteId'],
                'siteId',
                'site.test',
              )
              .having((error) => error.context?['serverIds'], 'serverIds', [
                'primary',
                'backup',
              ]),
        ),
      );
      expect(requestCount, 1);
    });

    test('写请求失败时不执行恢复或重试', () async {
      var requestCount = 0;
      var recoveryCount = 0;
      final recoveringClient = SitesHttpClient(
        config: const RequestConfig(
          baseUrl: 'https://test.example.com',
          enableLogger: false,
        ),
        readRequestRecovery: (exception) async {
          recoveryCount++;
          return const ReadRecoveryResult.recovered();
        },
      );
      addTearDown(recoveringClient.close);
      recoveringClient.dio.httpClientAdapter = mockAdapter;
      mockAdapter.register('/api/write', (options) {
        requestCount++;
        return mockAdapter._jsonResponse({}, 503);
      });

      await expectLater(
        recoveringClient.post<Map<String, dynamic>>('/api/write'),
        throwsA(isA<SitesNetworkException>()),
      );
      expect(requestCount, 1);
      expect(recoveryCount, 0);
    });

    test('绝对 URL 读取失败时不切换站点服务器', () async {
      var recoveryCount = 0;
      final recoveringClient = SitesHttpClient(
        config: const RequestConfig(
          baseUrl: 'https://test.example.com',
          enableLogger: false,
        ),
        readRequestRecovery: (exception) async {
          recoveryCount++;
          return const ReadRecoveryResult.recovered();
        },
      );
      addTearDown(recoveringClient.close);
      recoveringClient.dio.httpClientAdapter = mockAdapter;
      mockAdapter.registerError('/media/file', 503);

      await expectLater(
        recoveringClient.get<Map<String, dynamic>>(
          'https://cdn.example.com/media/file',
        ),
        throwsA(isA<SitesNetworkException>()),
      );
      expect(recoveryCount, 0);
    });

    test('getBytes 返回字节流', () async {
      mockAdapter.register('/api/file', (options) {
        final bytes = utf8.encode('hello world');
        return ResponseBody.fromBytes(
          bytes,
          200,
          headers: {
            Headers.contentTypeHeader: ['application/octet-stream'],
          },
        );
      });

      final response = await client.getBytes('/api/file');
      expect(response.data, isNotNull);
      expect(response.data, isA<List<int>>());
      expect(utf8.decode(response.data!), 'hello world');
    });

    test('拦截器链正确注入 Authorization 头', () async {
      String? receivedAuthHeader;

      mockAdapter.register('/api/check', (options) {
        receivedAuthHeader = options.headers['Authorization'];
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      await client.get<Map<String, dynamic>>('/api/check');

      expect(receivedAuthHeader, 'Bearer test-token');
    });

    test('拦截器链正确注入 User-Agent 头', () async {
      String? receivedUA;

      mockAdapter.register('/api/ua', (options) {
        receivedUA = options.headers['User-Agent'];
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      await client.get<Map<String, dynamic>>('/api/ua');

      expect(receivedUA, 'kikoenai-sites/0.1.0');
    });

    test('Cookie 在响应中被存储', () async {
      mockAdapter.register('/api/set-cookie', (options) {
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            'set-cookie': ['session=xyz789; Path=/'],
          },
        );
      });

      await client.get<Map<String, dynamic>>('/api/set-cookie');

      final cookies = client.cookieManager.getCookies('test.example.com');
      expect(cookies['session'], 'xyz789');
    });

    test('Cookie 在请求中被注入', () async {
      // 先设置 cookie
      client.cookieManager.setCookie('test.example.com', 'token', 'pre-set');

      String? receivedCookie;

      mockAdapter.register('/api/use-cookie', (options) {
        receivedCookie = options.headers['Cookie'];
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      await client.get<Map<String, dynamic>>('/api/use-cookie');

      expect(receivedCookie, contains('token=pre-set'));
    });

    test('updateBaseUrl 动态修改 baseUrl', () async {
      client.updateBaseUrl('https://new.example.com');

      expect(client.dio.options.baseUrl, 'https://new.example.com');
    });
  });
}
