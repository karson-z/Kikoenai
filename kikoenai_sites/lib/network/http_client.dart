import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'cookie_manager.dart';
import 'exception.dart';
import 'interceptor.dart';
import 'request_config.dart';
import 'unauthorized_interceptor.dart';

enum ReadRecoveryStatus { recovered, allServersUnavailable, skipped }

class ReadRecoveryResult {
  const ReadRecoveryResult._(this.status, {this.context = const {}});

  const ReadRecoveryResult.recovered() : this._(ReadRecoveryStatus.recovered);

  const ReadRecoveryResult.skipped() : this._(ReadRecoveryStatus.skipped);

  const ReadRecoveryResult.allServersUnavailable({
    required Map<String, dynamic> context,
  }) : this._(ReadRecoveryStatus.allServersUnavailable, context: context);

  final ReadRecoveryStatus status;
  final Map<String, dynamic> context;
}

typedef ReadRequestRecovery =
    Future<ReadRecoveryResult> Function(SitesNetworkException exception);

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
  final ReadRequestRecovery? _readRequestRecovery;
  bool _useProxy;

  SitesHttpClient._internal(
    this._dio,
    this.config,
    this.cookieManager,
    this._readRequestRecovery,
  ) : _useProxy = config.useProxy {
    _applyProxyPolicy(_useProxy);
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
    ReadRequestRecovery? readRequestRecovery,
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
    final client = SitesHttpClient._internal(dio, cfg, cm, readRequestRecovery);
    // 注入外部 tokenProvider / logger（覆盖默认拦截器中的）
    if (tokenProvider != null || logger != null) {
      client._dio.interceptors.clear();
      client._installInterceptors(tokenProvider: tokenProvider, logger: logger);
    }
    return client;
  }

  /// 内部暴露的 Dio 实例（慎用，主要用于特殊适配器设置）
  Dio get dio => _dio;

  bool get useProxy => _useProxy;

  /// 动态更新 baseUrl
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  /// 更新服务器地址及其代理策略。
  void updateConnection({required String baseUrl, required bool useProxy}) {
    _dio.options.baseUrl = baseUrl;
    if (_useProxy == useProxy) return;

    _useProxy = useProxy;
    final adapter = _dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.close(force: true);
      _dio.httpClientAdapter = IOHttpClientAdapter();
      _applyProxyPolicy(useProxy);
    }
  }

  void _applyProxyPolicy(bool useProxy) {
    final adapter = _dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) return;
    adapter.createHttpClient = () {
      final client = HttpClient();
      if (!useProxy) {
        client.findProxy = (_) => 'DIRECT';
      }
      return client;
    };
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

    // 4. Unauthorized (401 处理)
    if (config.onUnauthorized != null) {
      _dio.interceptors.add(
        UnauthorizedInterceptor(onUnauthorized: config.onUnauthorized),
      );
    }

    // 5. Logger
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

  SitesNetworkException _networkException(Object error, StackTrace stackTrace) {
    final exception = mapToSitesException(error);
    return SitesNetworkException(
      exception.message,
      originalError: exception.originalError,
      stackTrace: stackTrace,
      code: exception.code,
      context: exception.context,
    );
  }

  /// Executes a request and retries it once after an optional server recovery.
  Future<T> _execute<T>(
    Future<T> Function() request, {
    bool allowReadRecovery = false,
  }) async {
    try {
      return await request();
    } catch (e, st) {
      final exception = _networkException(e, st);
      final recovery = _readRequestRecovery;
      if (allowReadRecovery &&
          recovery != null &&
          exception.isRetryableReadFailure) {
        var recoveryResult = const ReadRecoveryResult.skipped();
        try {
          recoveryResult = await recovery(exception);
        } catch (_) {
          // Recovery is best-effort; preserve the original request failure.
        }
        switch (recoveryResult.status) {
          case ReadRecoveryStatus.recovered:
            try {
              return await request();
            } catch (retryError, retryStackTrace) {
              throw _networkException(retryError, retryStackTrace);
            }
          case ReadRecoveryStatus.allServersUnavailable:
            throw SitesNetworkException(
              '当前站点所有服务器均不可用',
              originalError: exception.originalError,
              stackTrace: st,
              code: SitesExceptionCode.allServersUnavailable,
              context: {...?exception.context, ...recoveryResult.context},
            );
          case ReadRecoveryStatus.skipped:
            break;
        }
      }
      throw exception;
    }
  }

  /// 泛型请求核心：统一异常映射
  Future<T> _request<T>(
    Future<Response> Function() request, {
    bool allowReadRecovery = false,
  }) async {
    final response = await _execute(
      request,
      allowReadRecovery: allowReadRecovery,
    );
    return response.data as T;
  }

  bool _usesConfiguredBaseUrl(String path) {
    return Uri.tryParse(path)?.hasScheme != true;
  }

  // ─── HTTP 方法 ─────────────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request<T>(
    () => _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ),
    allowReadRecovery: _usesConfiguredBaseUrl(path),
  );

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request<T>(
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
  }) => _request<T>(
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
  }) => _request<T>(
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
    return _execute(
      () => _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        options: (options ?? Options()).copyWith(
          responseType: ResponseType.bytes,
        ),
        cancelToken: cancelToken,
      ),
      allowReadRecovery: _usesConfiguredBaseUrl(path),
    );
  }

  /// 释放资源
  void close() {
    _dio.close();
  }
}
