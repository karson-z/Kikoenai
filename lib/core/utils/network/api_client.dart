import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/cache_service.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import '../../common/errors.dart';
import '../../common/global_exception.dart';
import '../../common/result.dart';
import '../../constants/app_constants.dart';
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
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    final authSession = await CacheService.instance.getAuthSession();

    if (authSession != null) {
      _cachedToken = authSession.token;
      return _cachedToken;
    }

    return null;
  }
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = '$newUrl/api';
    Log.i('ApiClient BaseUrl updated to: $newUrl', tag: 'API');
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
          // 关键：通过 extra 告诉拦截器不要重试，也不要处理 401
          extra: {
            'no_error_handling': true, // 自定义标记，需要在拦截器里处理(可选)
            'retry_count': 3, // 技巧：直接设置重试次数为3，欺骗拦截器不进行重试
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
  final interceptor = InterceptorsWrapper(
    onRequest: (options, handler) async {
      Log.i('REQ ${options.method} ${options.uri}', tag: 'API');
      options.headers['User-Agent'] =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36';
      options.headers['Referer'] = 'https://www.asmr.one/';
      options.headers['Origin'] = 'https://www.asmr.one';
      // Dart HttpClient 默认支持 gzip，显式声明可确保服务器知晓
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
      final context = AppConstants.rootNavigatorKey.currentContext;
      if (isUnauthorized) {
        if (context != null) {
          // 2. 显示带有按钮的错误 Toast
          AppToast.error(
            context,
            "登录已过期，请重新登录",
            action: SnackBarAction(
              label: '去登录',
              textColor: Colors.white,
              onPressed: () {
                // 3. 这里执行跳转逻辑
                // 方式 A: 如果你使用命名路由
                context.goNamed(AppRoutes.login);
              },
            ),
          );
        }
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
