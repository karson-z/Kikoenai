import 'package:dio/dio.dart';

import 'cookie_manager.dart';
import 'exception.dart';
import 'interceptor.dart';
import 'request_config.dart';

/// 站点 HTTP 客户端
///
/// 基于 [Dio] 封装，按固定顺序串联拦截器链：
///
/// ```
/// Request → HeaderInterceptor → AuthInterceptor →
///          CookieInterceptor → LoggerInterceptor → HTTP
/// ```
///
/// 业务侧通过 [SitesHttpClient.instance] 或自定义实例发起请求，
/// 所有异常会被统一转换为 [SitesNetworkException]。
class SitesHttpClient {
  final Dio _dio;
  final RequestConfig config;
  final SitesCookieManager cookieManager;

  SitesHttpClient._internal(this._dio, this.config, this.cookieManager) {
    _setupInterceptors();
  }

  /// 默认单例（使用 [RequestConfig.defaultConfig]）
  static final SitesHttpClient instance = SitesHttpClient(
    config: RequestConfig.defaultConfig(),
  );

  /// 工厂构造：自定义配置
  factory SitesHttpClient({
    RequestConfig? config,
    SitesCookieManager? cookieManager,
    TokenProvider? tokenProvider,
    void Function(String message)? logger,
  }) {
    final cfg = config ?? RequestConfig.defaultConfig();
    final cm = cookieManager ?? SitesCookieManager();
    final dio = Dio(
      BaseOptions(
        baseUrl: cfg.baseUrl,
        connectTimeout: cfg.connectTimeout,
        receiveTimeout: cfg.receiveTimeout,
        sendTimeout: cfg.sendTimeout,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    );
    final client = SitesHttpClient._internal(dio, cfg, cm);
    // 注入外部 tokenProvider / logger（覆盖默认拦截器中的）
    if (tokenProvider != null || logger != null) {
      client._dio.interceptors.clear();
      client._installInterceptors(tokenProvider: tokenProvider, logger: logger);
    }
    return client;
  }

  /// 内部暴露的 Dio 实例（慎用，主要用于特殊适配器设置）
  Dio get dio => _dio;

  /// 动态更新 baseUrl
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  /// 健康检查（快速超时 3 秒）
  Future<bool> checkHealth(String domain) async {
    try {
      final url = '$domain/api/health?cache=false';
      await _dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── 拦截器安装 ────────────────────────────────────────────

  void _setupInterceptors() {
    _installInterceptors();
  }

  void _installInterceptors({
    TokenProvider? tokenProvider,
    void Function(String message)? logger,
  }) {
    // 1. Header
    _dio.interceptors.add(HeaderInterceptor(config));

    // 2. Auth
    _dio.interceptors.add(AuthInterceptor(tokenProvider: tokenProvider));

    // 3. Cookie
    if (config.enableCookie) {
      _dio.interceptors.add(CookieInterceptor(cookieManager));
    }

    // 4. Logger
    if (config.enableLogger) {
      _dio.interceptors.add(
        LoggerInterceptor(
          log: logger,
          logRequestBody: true,
          logResponseBody: false,
        ),
      );
    }
  }

  // ─── 请求核心 ──────────────────────────────────────────────

  /// 泛型请求核心：统一异常映射
  Future<T> _request<T>(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } catch (e, st) {
      final exception = mapToSitesException(e);
      throw SitesNetworkException(
        exception.message,
        originalError: exception.originalError,
        stackTrace: st,
        code: exception.code,
        context: exception.context,
      );
    }
  }

  // ─── HTTP 方法 ─────────────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        () => _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        () => _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        () => _dio.put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        () => _dio.delete(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  /// 下载字节流（如文件下载）
  Future<Response<List<int>>> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        options: (options ?? Options()).copyWith(
          responseType: ResponseType.bytes,
        ),
        cancelToken: cancelToken,
      );
      return response;
    } catch (e, st) {
      final exception = mapToSitesException(e);
      throw SitesNetworkException(
        exception.message,
        originalError: exception.originalError,
        stackTrace: st,
        code: exception.code,
        context: exception.context,
      );
    }
  }

  /// 释放资源
  void close() {
    _dio.close();
  }
}
