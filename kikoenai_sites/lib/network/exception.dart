import 'package:dio/dio.dart';

/// 站点网络层统一异常
class SitesNetworkException implements Exception {
  /// 异常消息
  final String message;

  /// 原始异常对象
  final dynamic originalError;

  /// 堆栈信息
  final StackTrace? stackTrace;

  /// 异常类型代码
  final SitesExceptionCode code;

  /// 上下文信息（如请求路径、状态码等）
  final Map<String, dynamic>? context;

  const SitesNetworkException(
    this.message, {
    this.originalError,
    this.stackTrace,
    this.code = SitesExceptionCode.unknown,
    this.context,
  });

  /// Whether an idempotent read request may be retried after switching server.
  bool get isRetryableReadFailure {
    if (code == SitesExceptionCode.networkError ||
        code == SitesExceptionCode.certificateError) {
      return true;
    }
    if (code != SitesExceptionCode.serverError) return false;
    final status = context?['status'];
    return status == 502 || status == 503 || status == 504;
  }

  @override
  String toString() {
    final buffer = StringBuffer('SitesNetworkException');
    buffer.write(' [${code.name}]');
    buffer.write(': $message');
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    return buffer.toString();
  }
}

/// 站点异常类型枚举
enum SitesExceptionCode {
  /// 网络连接异常（超时、断网等）
  networkError,

  /// 服务端错误（5xx、4xx 等）
  serverError,

  /// 证书校验失败
  certificateError,

  /// 请求已取消
  cancelled,

  /// 数据解析失败
  parseError,

  /// 未授权（401）
  unauthorized,

  /// 禁止访问（403）
  forbidden,

  /// 资源未找到（404）
  notFound,

  /// 未知异常
  unknown,

  /// The selected site has no reachable configured server.
  allServersUnavailable,
}

/// 将 Dio 异常映射为 [SitesNetworkException]
SitesNetworkException mapToSitesException(dynamic error) {
  if (error is SitesNetworkException) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return SitesNetworkException(
          '网络异常，请检查连接',
          originalError: error,
          code: SitesExceptionCode.networkError,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final serverMsg = _serverMessage(status);
        final code = _statusCodeToCode(status);
        return SitesNetworkException(
          serverMsg,
          originalError: error,
          code: code,
          context: {
            'status': status,
            'response': error.response?.data,
            'path': error.requestOptions.path,
          },
        );
      case DioExceptionType.badCertificate:
        return SitesNetworkException(
          '证书校验失败',
          originalError: error,
          code: SitesExceptionCode.certificateError,
        );
      case DioExceptionType.cancel:
        return SitesNetworkException(
          '请求已取消',
          originalError: error,
          code: SitesExceptionCode.cancelled,
        );
      case DioExceptionType.unknown:
        return SitesNetworkException(
          '未知网络错误',
          originalError: error,
          code: SitesExceptionCode.unknown,
        );
      case DioExceptionType.transformTimeout:
        return SitesNetworkException(
          '数据转换超时',
          originalError: error,
          code: SitesExceptionCode.parseError,
        );
    }
  }

  if (error is FormatException || error is TypeError) {
    return SitesNetworkException(
      '数据解析失败',
      originalError: error,
      code: SitesExceptionCode.parseError,
    );
  }

  return SitesNetworkException(
    '未知错误',
    originalError: error,
    code: SitesExceptionCode.unknown,
  );
}

/// 根据状态码返回友好错误信息
String _serverMessage(int? status) {
  if (status == null) return '服务异常（未知状态码）';
  if (status >= 500) return '服务器内部错误 ($status)';
  if (status == 404) return '资源未找到 ($status)';
  if (status == 403) return '无访问权限 ($status)';
  if (status == 401) return '未授权，请重新登录 ($status)';
  if (status >= 400) return '请求错误 ($status)';
  return '服务异常 ($status)';
}

/// 状态码映射到异常类型
SitesExceptionCode _statusCodeToCode(int? status) {
  if (status == null) return SitesExceptionCode.serverError;
  if (status == 401) return SitesExceptionCode.unauthorized;
  if (status == 403) return SitesExceptionCode.forbidden;
  if (status == 404) return SitesExceptionCode.notFound;
  return SitesExceptionCode.serverError;
}
