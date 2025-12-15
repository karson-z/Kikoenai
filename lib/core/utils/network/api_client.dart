import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/errors.dart';
import '../../common/global_exception.dart';
import '../../common/result.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/login_dialog_manager.dart';
import '../log/logger.dart';

class ApiClient {
  final Dio _dio;
  String? _cachedToken;
  ApiClient._internal(this._dio) {
    _setupInterceptors(_dio, _tokenProvider);
  }

  /// 单例实例（同步）
  static final ApiClient instance = ApiClient._internal(
    Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    ),
  );

  /// 获取 token
  Future<String?> _tokenProvider() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(AppConstants.tokenKey);
    return _cachedToken;
  }

  /// 泛型请求核心方法
  Future<Result<T>> _request<T>(Future<Response> Function() request) async {
    try {
      final response = await request();

      return Result.success(
        // 注意：如果 options 设置为 bytes，这里的 T 应该是 List<int> 或 dynamic
        data: response.data as T,
        code: response.statusCode ?? -1,
        message: 'success',
      );
    } catch (e, st) {
      final exception = mapToGlobalException(e);
      throw GlobalException(
        exception.message,
        originalError: exception.originalError,
        stackTrace: st,
        code: exception.code,
        context: exception.context,
      );
    }
  }

  /// HTTP 方法封装（已添加 options 参数）

  Future<Result<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) =>
      _request<T>(
            () => _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<Result<T>> post<T>(
      String path, {
        dynamic data,
        Options? options,
      }) =>
      _request<T>(
            () => _dio.post(
          path,
          data: data,
          options: options,
        ),
      );

  Future<Result<T>> put<T>(
      String path, {
        dynamic data,
        Options? options,
      }) =>
      _request<T>(
            () => _dio.put(
          path,
          data: data,
          options: options,
        ),
      );

  Future<Result<T>> delete<T>(
      String path, {
        dynamic data,
        Options? options,
      }) =>
      _request<T>(
            () => _dio.delete(
          path,
          data: data,
          options: options,
        ),
      );
}

/// 拦截器注册
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
          options.headers['Authorization'] = 'Bearer $token';
        }
      }

      handler.next(options);
    },

    onResponse: (response, handler) async {
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
      int retryCount = (req.extra['retry_count'] as int?) ?? 0;

      // 401 登录处理
      final isUnauthorized = status == 401 ||
          (err.response?.data is Map &&
              err.response?.data['code'] == 401);

      if (isUnauthorized) {
        await LoginDialogManager().handleUnauthorized(
          err.response!,
          handler,
          dio,
          tokenProvider: tokenProvider,
        );
        return;
      }

      // 自动重试机制（仅 GET）
      final shouldRetry =
          (
              err.type == DioExceptionType.connectionError ||
                  err.type == DioExceptionType.connectionTimeout ||
                  err.type == DioExceptionType.receiveTimeout ||
                  (status != null && status >= 500)
          ) &&
          retryCount < 3;

      if (shouldRetry) {
        retryCount++;
        req.extra['retry_count'] = retryCount;

        Log.i('Retrying request... Attempt $retryCount', tag: 'API');
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));

        final newReq = Options(
          method: req.method,
          headers: req.headers,
          extra: req.extra,
        )
            .compose(
          dio.options,
          req.path,
          data: req.data,
          queryParameters: req.queryParameters,
        )
            .copyWith(baseUrl: req.baseUrl);

        try {
          final response = await dio.fetch(newReq);
          handler.resolve(response);
          return;
        } catch (e) {
          // 重试失败 → 不再触发 onError → 结束
          handler.reject(err);
          return;
        }
      }
    }
  );

  dio.interceptors.add(interceptor);
}

/// Riverpod Provider（直接返回单例）
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});
