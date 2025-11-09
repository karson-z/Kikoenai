import 'package:name_app/core/common/errors.dart';

class Result<T> {
  final T? data; // 成功时返回的数据
  final Failure? error; // 失败时的错误对象
  final int? code; // 状态码（例如 HTTP 状态码，或者业务自定义码）
  final String? message; // 简单提示信息

  const Result._({this.data, this.error, this.code, this.message});

  bool get isSuccess => error == null;

  /// 创建成功结果，可选择传入 code 与 message
  static Result<T> success<T>({
    T? data,
    int? code,
    String? message,
  }) =>
      Result._(
        data: data,
        code: code,
        message: message,
      );

  /// 创建失败结果，可选择传入 code 与 message
  static Result<T> failure<T>({
    required Failure error,
    int? code,
    String? message,
  }) =>
      Result._(
        error: error,
        code: code,
        message: message,
      );
}
