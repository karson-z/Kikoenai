import 'package:dio/dio.dart';
import 'package:name_app/core/domain/errors.dart';
import 'package:name_app/core/domain/result.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio, {Future<String?> Function()? tokenProvider});

  /// 工厂构造函数
  static ApiClient create({Future<String?> Function()? tokenProvider}) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
    ));

    // 使用提取的函数注册拦截器
    _setupInterceptors(dio, tokenProvider);

    return ApiClient(dio, tokenProvider: tokenProvider);
  }

  /// 通用请求封装
  Future<Result<T>> _request<T>(
    Future<Response> Function() request,
    T Function(dynamic data)? fromJson,
  ) async {
    try {
      final response = await request();
      final code = response.statusCode ?? -1;
      final body = response.data;

      if (body is Map<String, dynamic>) {
        final code = body['code'] ?? response.statusCode ?? -1;
        final message = body['message'] ?? 'Unknown error';
        final data = body['data'];
        final parsed = fromJson != null ? fromJson(data) : data;
        return Result.success(data: parsed as T, code: code, message: message);
      }
      return Result.failure(
        error: ParseFailure('响应格式错误', code: code),
        code: code,
        message: 'Invalid response',
      );
    } catch (e) {
      final failure = mapException(e);
      return Result.failure(
        error: failure,
        message: failure.message,
      );
    }
  }

  ///快捷方法封装
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) =>
      _request(
          () => _dio.get(path, queryParameters: queryParameters), fromJson);

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
  }) =>
      _request(() => _dio.post(path, data: data), fromJson);

  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
  }) =>
      _request(() => _dio.put(path, data: data), fromJson);

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
  }) =>
      _request(() => _dio.delete(path, data: data), fromJson);
}

/// 提取出的拦截器配置函数
void _setupInterceptors(
  Dio dio,
  Future<String?> Function()? tokenProvider,
) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        Log.i('REQ ${options.method} ${options.uri}', tag: 'API');

        if (tokenProvider != null) {
          final token = await tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['token'] = token;
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        Log.i(
          'RES [${response.statusCode}] ${response.requestOptions.uri}',
          tag: 'API',
        );
        handler.next(response);
      },
      onError: (DioException err, handler) async {
        final status = err.response?.statusCode;
        Log.e('ERR [${status ?? ''}] ${err.message}', tag: 'API');

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
          } catch (_) {}
        }

        handler.next(err);
      },
    ),
  );
}
