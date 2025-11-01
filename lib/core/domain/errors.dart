import 'package:dio/dio.dart';

abstract class Failure {
  final String message;
  final Object? cause;
  const Failure(this.message, {this.cause});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(String message, {this.statusCode, Object? cause})
      : super(message, cause: cause);
}

class ParseFailure extends Failure {
  const ParseFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

Failure mapException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('网络异常，请检查连接', cause: error);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return ServerFailure('服务异常 (${status ?? '未知状态码'})',
            statusCode: status, cause: error);
      case DioExceptionType.cancel:
        return UnknownFailure('请求已取消', cause: error);
      case DioExceptionType.badCertificate:
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
