/// 站点请求配置
///
/// 统一管理 [SitesHttpClient] 的基础参数：baseUrl、超时时间、默认请求头等。
class RequestConfig {
  /// 基础地址
  final String baseUrl;

  /// 连接超时
  final Duration connectTimeout;

  /// 接收超时
  final Duration receiveTimeout;

  /// 发送超时
  final Duration sendTimeout;

  /// 默认 User-Agent
  final String userAgent;

  /// 默认 Referer
  final String referer;

  /// 默认 Accept
  final String accept;

  /// 额外的默认请求头
  final Map<String, String> extraHeaders;

  /// 是否启用日志
  final bool enableLogger;

  /// 是否启用 Cookie 管理
  final bool enableCookie;

  const RequestConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 10),
    this.userAgent = 'kikoenai-sites/0.1.0',
    this.referer = 'https://www.asmr.one/',
    this.accept = 'application/json',
    this.extraHeaders = const {},
    this.enableLogger = true,
    this.enableCookie = true,
  });

  /// 默认配置
  factory RequestConfig.defaultConfig() {
    return const RequestConfig(
      baseUrl: 'https://api.asmr-200.com/api',
    );
  }

  /// 复制并修改部分字段
  RequestConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? userAgent,
    String? referer,
    String? accept,
    Map<String, String>? extraHeaders,
    bool? enableLogger,
    bool? enableCookie,
  }) {
    return RequestConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      userAgent: userAgent ?? this.userAgent,
      referer: referer ?? this.referer,
      accept: accept ?? this.accept,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      enableLogger: enableLogger ?? this.enableLogger,
      enableCookie: enableCookie ?? this.enableCookie,
    );
  }

  /// 合并所有默认请求头
  Map<String, String> get defaultHeaders => {
    'Accept': accept,
    'User-Agent': userAgent,
    'Referer': referer,
    ...extraHeaders,
  };
}
