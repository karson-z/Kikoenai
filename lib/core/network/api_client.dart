import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  final Dio _dio;
  ApiClient(this._dio);

  static ApiClient create() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0 Safari/537.36',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        Log.i('REQ ${options.method} ${options.uri}', tag: 'API');
        handler.next(options);
      },
      onResponse: (response, handler) {
        Log.i('RES [${response.statusCode}] ${response.requestOptions.uri}', tag: 'API');
        handler.next(response);
      },
      onError: (DioException err, handler) async {
        final status = err.response?.statusCode;
        Log.e('ERR [${status ?? ''}] ${err.message}', tag: 'API');

        // 简单重试策略：GET 请求发生连接/超时或 5xx 时重试最多 2 次
        final req = err.requestOptions;
        final method = req.method.toUpperCase();
        int retryCount = (req.extra['retry_count'] as int?) ?? 0;
        final shouldRetry = method == 'GET' &&
            (err.type == DioExceptionType.connectionError ||
             err.type == DioExceptionType.connectionTimeout ||
             err.type == DioExceptionType.receiveTimeout ||
             (status != null && status >= 500)) &&
            retryCount < 2;

        if (shouldRetry) {
          retryCount++;
          req.extra['retry_count'] = retryCount;
          Log.w('Retry #$retryCount ${req.uri}', tag: 'API');
          try {
            final resp = await dio.fetch(req);
            return handler.resolve(resp);
          } catch (e) {
            // fall through to original error
          }
        }

        handler.next(err);
      },
    ));
    return ApiClient(dio);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
}