import 'dart:async';
import 'package:dio/dio.dart';
import 'package:name_app/core/common/errors.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/core/widgets/login_dialog_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../log/logger.dart';

class ApiClient {
  final Dio _dio;

  /// 默认构造函数，用于正常使用
  ApiClient(this._dio);

  /// 工厂构造函数
  factory ApiClient.create() {
    // 定义tokenProvider回调，从SharedPreferences获取最新token
    Future<String?> tokenProvider() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    }

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

    // 设置拦截器
    _setupInterceptors(dio, tokenProvider);

    return ApiClient(dio);
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
        final parsed = fromJson != null && data != null ? fromJson(data) : data;
        return Result.success(data: parsed as T?, code: code, message: message);
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
  final interceptor = InterceptorsWrapper(
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
    onResponse: (response, handler) async {
      Log.i(
        'RES [${response.statusCode}] ${response.requestOptions.uri}',
        tag: 'API',
      );

      if (response.statusCode == 401 ||
          (response.data is Map && response.data['code'] == 401)) {
        await LoginDialogManager().handleUnauthorized(response, handler, dio,
            tokenProvider: tokenProvider);
        return; // 拦截，不继续处理
      }
      // 正常响应继续处理
      handler.next(response);
    },
    onError: (DioException err, handler) async {
      final status = err.response?.statusCode;
      Log.e('ERR [${status ?? ''}] ${err.message}', tag: 'API');

      final req = err.requestOptions;
      final method = req.method.toUpperCase();
      int retryCount = (req.extra['retry_count'] as int?) ?? 0;

      // 其他错误的重试逻辑
      final shouldRetry = method == 'GET' &&
          (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout ||
              (status != null && status >= 500)) &&
          retryCount < 3;

      if (shouldRetry) {
        retryCount++;
        req.extra['retry_count'] = retryCount;
        Log.i('Retrying request... Attempt $retryCount', tag: 'API');

        // 添加延迟避免立即重试
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        try {
          final response = await dio.fetch(req);
          handler.resolve(response);
        } catch (e) {
          handler.next(err);
        }
      } else {
        handler.next(err);
      }
    },
  );

  // 添加拦截器
  dio.interceptors.add(interceptor);
}
