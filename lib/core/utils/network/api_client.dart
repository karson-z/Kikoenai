import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import '../../service/cache/cache_service.dart';
import '../../common/errors.dart';
import '../../common/global_exception.dart';
import '../../common/result.dart';
import '../../constants/app_constants.dart';

class ApiClient {
  final Dio _dio;
  String? _cachedToken;

  ApiClient._internal(this._dio) {
    _setupInterceptors(_dio, _tokenProvider);
  }

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
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    final authSession = CacheService.instance.getAuthSession();

    if (authSession != null) {
      _cachedToken = authSession.token;
      return _cachedToken;
    }

    return null;
  }

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = '$newUrl/api';
    // 修改日志调用，手动添加 [API] 标签前缀
    KikoenaiLogger().i('[API] ApiClient BaseUrl updated to: $newUrl');
  }

  Future<bool> checkHealth(String domain) async {
    try {
      // 这里的 url 必须是完整的 (http开头)，Dio 会自动忽略 options.baseUrl
      final url = '$domain/api/health?cache=false';

      await _dio.get(
        url,
        options: Options(
          // 覆盖超时时间，健康检查要快 (3秒)
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=utf-8',
          },
        ),
      );
      return true;
    } catch (e) {
      // 健康检查失败是正常的，静默返回 false
      return false;
    }
  }

  /// 泛型请求核心方法
  Future<Result<T>> _request<T>(Future<Response> Function() request) async {
    try {
      final response = await request();

      return Result.success(
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
  final customInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) async {
      KikoenaiLogger().i('[API] REQ ${options.method} ${options.uri}');
      options.headers['Referer'] = 'https://www.asmr.one/';
      options.headers['Origin'] = 'https://www.asmr.one';
      options.headers['Accept-Encoding'] = 'gzip';

      if (tokenProvider != null) {
        final token = await tokenProvider();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    },
    onResponse: (response, handler) async {
      KikoenaiLogger().i(
        '[API] RES [${response.statusCode}] ${response.requestOptions.uri}',
      );
      handler.next(response);
    },
    onError: (DioException err, handler) async {
      final status = err.response?.statusCode;
      KikoenaiLogger().e('[API] ERR [${status ?? ''}] ${err.message}');

      // 401 登录处理
      final isUnauthorized = status == 401 ||
          (err.response?.data is Map && err.response?.data['code'] == 401);

      if (isUnauthorized) {
        final context = AppConstants.rootNavigatorKey.currentContext;
        if (context != null) {
          KikoenaiToast.error(
            context: context,
            "登录已过期，请重新登录",
            action: SnackBarAction(
              label: '去登录',
              textColor: Colors.white,
              onPressed: () {
                context.go(AppRoutes.login);
              },
            ),
          );
        }
        return handler.next(err);
      }
      handler.next(err);
    },
  );

  // 添加自定义拦截器
  dio.interceptors.add(customInterceptor);
  // dio.interceptors.add(RetryInterceptor(
  //   dio: dio,
  //   logPrint: (message) => KikoenaiLogger().w('[API Retry] $message'),
  //   retries: 3,
  //   retryDelays: const [
  //     Duration(seconds: 1),
  //     Duration(seconds: 2),
  //     Duration(seconds: 3),
  //   ],
  //   retryEvaluator: (error, attempt) {
  //     // 401/403 不重试
  //     if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
  //       return false;
  //     }
  //     return DefaultRetryEvaluator(defaultRetryableStatuses).evaluate(error, attempt);
  //   },
  // ));
}
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});