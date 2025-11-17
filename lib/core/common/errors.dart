import 'package:dio/dio.dart';

import 'global_exception.dart';

/// 统一异常映射：将底层错误转换成全局异常
GlobalException mapToGlobalException(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return GlobalException(
          '网络异常，请检查连接',
          originalError: error,
          code: 'NETWORK_ERROR',
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final message = _serverMessage(status);
        return GlobalException(
          message,
          originalError: error,
          code: 'SERVER_ERROR',
          context: {'status': status, 'response': error.response?.data},
        );

      case DioExceptionType.badCertificate:
        return GlobalException(
          '证书校验失败',
          originalError: error,
          code: 'CERTIFICATE_ERROR',
        );

      case DioExceptionType.cancel:
        return GlobalException(
          '请求已取消',
          originalError: error,
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
      default:
        return GlobalException(
          '未知网络错误',
          originalError: error,
          code: 'UNKNOWN_NETWORK_ERROR',
        );
    }
  }

  if (error is FormatException || error is TypeError) {
    return GlobalException(
      '数据解析失败',
      originalError: error,
      code: 'PARSE_ERROR',
    );
  }

  // 默认未知错误
  return GlobalException(
    '未知错误',
    originalError: error,
    code: 'UNKNOWN_ERROR',
  );
}

/// 根据状态码返回更友好的服务端错误信息
String _serverMessage(int? status) {
  if (status == null) return '服务异常（未知状态码）';
  if (status >= 500) return '服务器内部错误 ($status)';
  if (status == 404) return '资源未找到 ($status)';
  if (status == 403) return '无访问权限 ($status)';
  if (status == 401) return '未授权，请重新登录 ($status)';
  if (status >= 400) return '请求错误 ($status)';
  return '服务异常 ($status)';
}
