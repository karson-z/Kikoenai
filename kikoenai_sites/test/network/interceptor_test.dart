import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/network/cookie_manager.dart';
import 'package:kikoenai_sites/network/interceptor.dart';
import 'package:kikoenai_sites/network/request_config.dart';

void main() {
  group('HeaderInterceptor', () {
    test('自动添加 User-Agent / Referer / Accept', () async {
      const config = RequestConfig(
        baseUrl: 'https://test.com',
        userAgent: 'TestUA/1.0',
        referer: 'https://ref.com',
        accept: 'application/json',
      );
      final interceptor = HeaderInterceptor(config);
      final options = RequestOptions(path: '/api');
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['User-Agent'], 'TestUA/1.0');
      expect(options.headers['Referer'], 'https://ref.com');
      expect(options.headers['Accept'], 'application/json');
      expect(handler.nextCalled, isTrue);
    });

    test('不覆盖已手动设置的请求头', () {
      const config = RequestConfig(
        baseUrl: 'https://test.com',
        userAgent: 'AutoUA',
      );
      final interceptor = HeaderInterceptor(config);
      final options = RequestOptions(
        path: '/api',
        headers: {'User-Agent': 'ManualUA'},
      );
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['User-Agent'], 'ManualUA');
    });

    test('extraHeaders 被合并', () {
      const config = RequestConfig(
        baseUrl: 'https://test.com',
        extraHeaders: {'X-App': 'kikoenai'},
      );
      final interceptor = HeaderInterceptor(config);
      final options = RequestOptions(path: '/api');
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['X-App'], 'kikoenai');
    });
  });

  group('AuthInterceptor', () {
    test('tokenProvider 返回 token 时注入 Authorization', () async {
      final interceptor = AuthInterceptor(
        tokenProvider: () async => 'my-token',
      );
      final options = RequestOptions(path: '/api');
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);
      // 等待异步完成
      await Future.delayed(Duration.zero);

      expect(options.headers['Authorization'], 'Bearer my-token');
    });

    test('tokenProvider 返回 null 时不注入 Authorization', () async {
      final interceptor = AuthInterceptor(
        tokenProvider: () async => null,
      );
      final options = RequestOptions(path: '/api');
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);
      await Future.delayed(Duration.zero);

      expect(options.headers['Authorization'], isNull);
    });

    test('已手动设置 Authorization 时不覆盖', () async {
      final interceptor = AuthInterceptor(
        tokenProvider: () async => 'auto-token',
      );
      final options = RequestOptions(
        path: '/api',
        headers: {'Authorization': 'Bearer manual-token'},
      );
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);
      await Future.delayed(Duration.zero);

      expect(options.headers['Authorization'], 'Bearer manual-token');
    });

    test('无 tokenProvider 时直接放行', () async {
      final interceptor = AuthInterceptor();
      final options = RequestOptions(path: '/api');
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);
      await Future.delayed(Duration.zero);

      expect(options.headers['Authorization'], isNull);
      expect(handler.nextCalled, isTrue);
    });
  });

  group('CookieInterceptor', () {
    test('请求时注入 Cookie 头', () {
      final cm = SitesCookieManager();
      cm.setCookie('test.com', 'session', 'abc');
      final interceptor = CookieInterceptor(cm);
      final options = RequestOptions(
        path: '/api',
        baseUrl: 'https://test.com',
      );
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['Cookie'], contains('session=abc'));
    });

    test('不覆盖手动设置的 Cookie 头', () {
      final cm = SitesCookieManager();
      cm.setCookie('test.com', 'session', 'abc');
      final interceptor = CookieInterceptor(cm);
      final options = RequestOptions(
        path: '/api',
        baseUrl: 'https://test.com',
        headers: {'Cookie': 'manual=1'},
      );
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['Cookie'], 'manual=1');
    });

    test('响应时解析 Set-Cookie 头', () {
      final cm = SitesCookieManager();
      final interceptor = CookieInterceptor(cm);
      final response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/api',
          baseUrl: 'https://test.com',
        ),
        statusCode: 200,
        headers: Headers.fromMap({
          'set-cookie': ['token=xyz; Path=/'],
        }),
      );
      final handler = _TestResponseHandler();

      interceptor.onResponse(response, handler);

      expect(cm.getCookies('test.com')['token'], 'xyz');
      expect(handler.nextCalled, isTrue);
    });

    test('无 Set-Cookie 时不写入', () {
      final cm = SitesCookieManager();
      final interceptor = CookieInterceptor(cm);
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/api'),
        statusCode: 200,
      );
      final handler = _TestResponseHandler();

      interceptor.onResponse(response, handler);

      expect(cm.all, isEmpty);
    });
  });

  group('LoggerInterceptor', () {
    test('onRequest 打印日志并放行', () {
      final logs = <String>[];
      final interceptor = LoggerInterceptor(
        log: logs.add,
        logRequestBody: true,
      );
      final options = RequestOptions(path: '/api', method: 'GET');
      options.data = {'key': 'value'};
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(logs, isNotEmpty);
      expect(logs.first, contains('[Sites] REQ'));
      expect(logs.first, contains('GET'));
      expect(logs.first, contains('body'));
      expect(handler.nextCalled, isTrue);
    });

    test('onResponse 打印日志并放行', () {
      final logs = <String>[];
      final interceptor = LoggerInterceptor(log: logs.add);
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/api'),
        statusCode: 200,
      );
      final handler = _TestResponseHandler();

      interceptor.onResponse(response, handler);

      expect(logs, isNotEmpty);
      expect(logs.first, contains('[Sites] RES'));
      expect(logs.first, contains('200'));
      expect(handler.nextCalled, isTrue);
    });

    test('onError 打印日志并放行', () {
      final logs = <String>[];
      final interceptor = LoggerInterceptor(log: logs.add);
      final err = DioException(
        requestOptions: RequestOptions(path: '/api'),
        message: '网络错误',
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api'),
          statusCode: 500,
        ),
      );
      final handler = _TestErrorHandler();

      interceptor.onError(err, handler);

      expect(logs, isNotEmpty);
      expect(logs.first, contains('[Sites] ERR'));
      expect(logs.first, contains('500'));
      expect(handler.nextCalled, isTrue);
    });
  });
}

// ─── 测试用 Handler 桩 ──────────────────────────────────────

class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  RequestOptions? receivedOptions;

  @override
  void next(RequestOptions options) {
    nextCalled = true;
    receivedOptions = options;
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  Response? receivedResponse;

  @override
  void next(Response response) {
    nextCalled = true;
    receivedResponse = response;
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  DioException? receivedError;

  @override
  void next(DioException err) {
    nextCalled = true;
    receivedError = err;
  }
}
