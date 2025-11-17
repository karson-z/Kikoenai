import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/common/global_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/errors.dart';
import '../../common/result.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/login_dialog_manager.dart';
import '../log/logger.dart';

class ApiClient {
  final Dio _dio;

  // 私有构造
  ApiClient._internal(this._dio) {
    _setupInterceptors(_dio, _tokenProvider);
  }

  // 单例
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

  // token 提供者
  static Future<String?> _tokenProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // 请求封装
  Future<Result<Map<String, dynamic>>> _request(
      Future<Response> Function() request) async {
    try {
      final response = await request();
      return Result.success(
        data: response.data,
        code: response.statusCode ?? -1,
        message: 'success',
      );
    } catch (e,st) {
      final exception = mapToGlobalException(e);
      final exceptionWithStack = GlobalException(
        exception.message,
        originalError: exception.originalError,
        stackTrace: st,
        code: exception.code,
        context: exception.context,
      );
      throw exceptionWithStack;
    }
  }

  Future<Result<Map<String, dynamic>>> get(String path,
      {Map<String, dynamic>? queryParameters}) =>
      _request(() => _dio.get(path, queryParameters: queryParameters));

  Future<Result<Map<String, dynamic>>> post(String path, {dynamic data}) =>
      _request(() => _dio.post(path, data: data));

  Future<Result<Map<String, dynamic>>> put(String path, {dynamic data}) =>
      _request(() => _dio.put(path, data: data));

  Future<Result<Map<String, dynamic>>> delete(String path, {dynamic data}) =>
      _request(() => _dio.delete(path, data: data));
}

// 拦截器
void _setupInterceptors(Dio dio, Future<String?> Function()? tokenProvider) {
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
      Log.i('RES [${response.statusCode}] ${response.requestOptions.uri}', tag: 'API');
      handler.next(response);
    },
    onError: (DioException err, handler) async {
      final status = err.response?.statusCode;
      Log.e('ERR [${status ?? ''}] ${err.message}', tag: 'API');

      final req = err.requestOptions;
      final method = req.method.toUpperCase();
      int retryCount = (req.extra['retry_count'] as int?) ?? 0;
      if (err.response?.statusCode == 401 ||
          (err.response?.data['code'] is Map && err.response?.data['code'] == 401)) {
        await LoginDialogManager().handleUnauthorized(err.response!, handler, dio,
            tokenProvider: tokenProvider);
        return;
      }
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

  dio.interceptors.add(interceptor);
}

/// Riverpod Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance; // ✅ 直接使用同步单例
});
