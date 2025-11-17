import 'package:name_app/core/common/errors.dart';

class Result<T> {
  final T? data; // 成功时返回的数据
  final int? code; // 状态码（例如 HTTP 状态码，或者业务自定义码）
  final String? message; // 简单提示信息

  const Result._({this.data, this.code, this.message});

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
}
