import 'package:dio/dio.dart';

import 'cookie_manager.dart';
import 'request_config.dart';

/// ───────────────────────────────────────────────────────────
/// 请求拦截链
///
///  Request
///    │
///    ▼
///  HeaderInterceptor  ── 自动添加 User-Agent / Referer / Accept
///    │
///    ▼
///  AuthInterceptor     ── 注入 Authorization Bearer Token
///    │
///    ▼
///  CookieInterceptor    ── 注入 Cookie 头 & 解析 Set-Cookie 响应
///    │
///    ▼
///  LoggerInterceptor    ── 打印请求 / 响应 / 错误日志
///    │
///    ▼
///   HTTP
/// ───────────────────────────────────────────────────────────

/// Token 提供函数类型
typedef TokenProvider = Future<String?> Function();

/// ───────────────────────────────────────────────────────────
/// 1. HeaderInterceptor
/// ───────────────────────────────────────────────────────────

/// 自动添加通用请求头
///
/// - User-Agent
/// - Referer
/// - Accept
class HeaderInterceptor extends Interceptor {
  final RequestConfig config;

  HeaderInterceptor(this.config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers;

    // 仅在未被手动设置时填充默认值
    headers.putIfAbsent('User-Agent', () => config.userAgent);
    headers.putIfAbsent('Referer', () => config.referer);
    headers.putIfAbsent('Accept', () => config.accept);

    // 额外默认头
    for (final entry in config.extraHeaders.entries) {
      headers.putIfAbsent(entry.key, () => entry.value);
    }

    handler.next(options);
  }
}

/// ───────────────────────────────────────────────────────────
/// 2. AuthInterceptor
/// ───────────────────────────────────────────────────────────

/// 处理 Token / Authorization
///
/// 通过 [tokenProvider] 异步获取 token，自动注入 `Authorization: Bearer <token>`。
/// 当请求已手动设置 Authorization 头时跳过。
class AuthInterceptor extends Interceptor {
  final TokenProvider? tokenProvider;

  AuthInterceptor({this.tokenProvider});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 已手动设置则不覆盖
    if (options.headers['Authorization'] != null) {
      return handler.next(options);
    }

    if (tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}

/// ───────────────────────────────────────────────────────────
/// 3. CookieInterceptor
/// ───────────────────────────────────────────────────────────

/// Cookie 管理拦截器
///
/// 请求阶段：根据 host 注入 Cookie 头
/// 响应阶段：解析 Set-Cookie 头并存入 [SitesCookieManager]
class CookieInterceptor extends Interceptor {
  final SitesCookieManager cookieManager;

  CookieInterceptor(this.cookieManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final host = options.uri.host;
    final cookieHeader = cookieManager.getCookieHeader(host);
    if (cookieHeader.isNotEmpty) {
      // 不覆盖手动设置的 Cookie
      options.headers.putIfAbsent('Cookie', () => cookieHeader);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final host = response.requestOptions.uri.host;
    final setCookie = response.headers.map['set-cookie'];
    if (setCookie != null) {
      cookieManager.parseSetCookieHeader(host, setCookie);
    }
    handler.next(response);
  }
}

/// ───────────────────────────────────────────────────────────
/// 4. LoggerInterceptor
/// ───────────────────────────────────────────────────────────

/// 日志拦截器
///
/// 打印：
/// - 请求：`[Sites] REQ <method> <uri>`
/// - 响应：`[Sites] RES [<status>] <uri>`
/// - 错误：`[Sites] ERR [<status>] <message>`
class LoggerInterceptor extends Interceptor {
  /// 自定义日志输出函数（默认 print）
  final void Function(String message) log;

  /// 是否打印请求体
  final bool logRequestBody;

  /// 是否打印响应体
  final bool logResponseBody;

  LoggerInterceptor({
    void Function(String message)? log,
    this.logRequestBody = false,
    this.logResponseBody = false,
  }) : log = log ?? _defaultLog;

  static void _defaultLog(String message) {
    // ignore: avoid_print
    print(message);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer('[Sites] REQ ${options.method} ${options.uri}');
    if (logRequestBody && options.data != null) {
      buffer.write('\n  body: ${options.data}');
    }
    log(buffer.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buffer = StringBuffer(
      '[Sites] RES [${response.statusCode}] ${response.requestOptions.uri}',
    );
    if (logResponseBody && response.data != null) {
      buffer.write('\n  data: ${response.data}');
    }
    log(buffer.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    log('[Sites] ERR [${status ?? ''}] ${err.message}');
    handler.next(err);
  }
}
