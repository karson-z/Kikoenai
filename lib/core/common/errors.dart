import 'package:dio/dio.dart';

/// 基础错误类型：所有错误的父类
abstract class Failure {
  final int code;
  final String message;
  final Object? cause;

  const Failure(this.message, {this.code = -1, this.cause});

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

/// 网络相关错误（超时、连接失败等）
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {int code = -1, Object? cause})
      : super(message, code: code, cause: cause);
}

/// 服务端返回错误（4xx、5xx）
class ServerFailure extends Failure {
  const ServerFailure(String message, {int code = -1, Object? cause})
      : super(message, code: code, cause: cause);

  @override
  String toString() => 'ServerFailure(code: $code, message: $message)';
}

/// 数据解析失败（JSON格式异常、类型错误）
class ParseFailure extends Failure {
  const ParseFailure(String message, {int code = -1, Object? cause})
      : super(message, code: code, cause: cause);
}

/// 未知错误（兜底类型）
class UnknownFailure extends Failure {
  const UnknownFailure(String message, {int code = -1, Object? cause})
      : super(message, code: code, cause: cause);
}

/// 统一异常映射：将底层错误转换成领域错误类型
Failure mapException(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure('网络异常，请检查连接', cause: error);

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final message = _serverMessage(status);
        return ServerFailure(message, code: status ?? -1, cause: error);

      case DioExceptionType.badCertificate:
        return NetworkFailure('证书校验失败', cause: error);

      case DioExceptionType.cancel:
        return UnknownFailure('请求已取消', cause: error);

      case DioExceptionType.unknown:
      default:
        return UnknownFailure('未知错误', cause: error);
    }
  }

  if (error is FormatException || error is TypeError) {
    return ParseFailure('数据解析失败', cause: error);
  }

  return UnknownFailure('未知错误', cause: error);
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
