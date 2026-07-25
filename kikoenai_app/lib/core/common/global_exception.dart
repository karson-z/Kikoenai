class GlobalException implements Exception {
  /// 异常消息
  final String message;

  /// 原始异常对象（可以是任何类型）
  final dynamic originalError;

  /// 异常堆栈信息
  final StackTrace? stackTrace;

  /// 可选的异常类型或代码
  final String? code;

  /// 上下文信息（比如请求参数、方法名等）
  final Map<String, dynamic>? context;

  GlobalException(
      this.message, {
        this.originalError,
        this.stackTrace,
        this.code,
        this.context,
      });

  @override
  String toString() {
    final buffer = StringBuffer('GlobalException');
    if (code != null) buffer.write(' [code: $code]');
    buffer.write(': $message');
    if (originalError != null) buffer.write('\nOriginal error: $originalError');
    if (stackTrace != null) buffer.write('\nStack trace: $stackTrace');
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    return buffer.toString();
  }
}
