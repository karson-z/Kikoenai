import 'errors.dart';

class Result<T> {
  final T? data; // 成功时返回的数据
  final Failure? error; // 失败时的错误对象
  final int? code; // 状态码（例如 HTTP 状态码，或者业务自定义码）
  final String? message; // 简单提示信息

  const Result._({this.data, this.error, this.code, this.message});

  bool get isSuccess => error == null;

  static Result<T> success<T>({
    required T data,
    int code = 200,
    String message = 'Success',
  }) =>
      Result._(data: data, code: code, message: message);

  static Result<T> failure<T>({
    required Failure error,
    int code = -1,
    String message = 'Unknown error',
  }) =>
      Result._(error: error, code: code, message: message);
}
