import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

class DioClient {
  static final Dio _dio = Dio();

  // 对应 JS 中的 Config.retry 等全局配置
  static int defaultRetryLimit = 5;
  static int defaultRetryDelay = 2000;

  static void init({String? proxyHost, int? proxyPort}) {
    if (proxyHost != null && proxyPort != null) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          // 一比一复刻 JS 的 TUNNEL_OPTIONS 代理逻辑
          client.findProxy = (uri) => "PROXY $proxyHost:$proxyPort";
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }
  }

  static Future<Response> retryGet(String url, {
    Map<String, dynamic>? headers,
    int retryCount = 0,
    Map<String, dynamic>? customRetryConfig, // 对应 JS 的 config.retry
  }) async {
    // 1. 复刻 JS 的超时时长计算逻辑
    int timeout = 10000;
    if (url.contains('dlsite')) {
      timeout = 10000; // 对应 Config.dlsiteTimeout
    } else if (url.contains('hvdb')) {
      timeout = 10000; // 对应 Config.hvdbTimeout
    }

    final int limit = customRetryConfig?['limit'] ?? defaultRetryLimit;
    final int delay = customRetryConfig?['retryDelay'] ?? defaultRetryDelay;

    // 2. 复刻 JS 的 CancelToken 强制超时逻辑
    final cancelToken = CancelToken();
    final timer = Timer(Duration(milliseconds: timeout), () {
      cancelToken.cancel("Timeout of ${timeout}ms.");
    });

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      timer.cancel(); // 请求成功，清除定时器
      return response;
    } catch (e) {
      timer.cancel();

      // 3. 复刻 JS 的重试判断：if (config.retryCount < limit && !error.response)
      bool shouldRetry = false;
      if (e is DioException) {
        // 只有在没有响应（网络问题、超时等）时才重试，对应 !error.response
        if (e.response == null && retryCount < limit) {
          shouldRetry = true;
        }
      }

      if (shouldRetry) {
        await Future.delayed(Duration(milliseconds: delay));
        print('$url 第 ${retryCount + 1} 次重试请求');

        return retryGet(
          url,
          headers: headers,
          retryCount: retryCount + 1,
          customRetryConfig: customRetryConfig,
        );
      } else {
        rethrow;
      }
    }
  }
}