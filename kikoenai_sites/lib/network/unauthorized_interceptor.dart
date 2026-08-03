import 'package:dio/dio.dart';

/// 401 未授权回调类型。
///
/// 当请求收到 401 响应时触发，业务侧注入实现以处理跳登录 / 清 token 等。
typedef OnUnauthorized = void Function(RequestOptions requestOptions);

/// 401 未授权拦截器。
///
/// 监听响应错误，当状态码为 401（或响应体 `code` 字段为 401）时，
/// 调用 [onUnauthorized] 回调通知业务层。
///
/// 回调执行后仍会继续传递错误，业务侧可在回调中完成 UI 跳转等操作，
/// 同时调用方仍能捕获到 [SitesNetworkException]。
class UnauthorizedInterceptor extends Interceptor {
  final OnUnauthorized? onUnauthorized;

  UnauthorizedInterceptor({this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final isUnauthorized = status == 401 ||
        (err.response?.data is Map && err.response?.data['code'] == 401);

    if (isUnauthorized && onUnauthorized != null) {
      onUnauthorized!(err.requestOptions);
    }

    handler.next(err);
  }
}
