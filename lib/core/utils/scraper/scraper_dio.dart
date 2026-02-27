import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

class DioClient {
  static final Dio _dio = Dio();

  static int defaultRetryLimit = 5;
  static int defaultRetryDelay = 2000;

  static void setProxy(String? proxyHost, String? proxyPort) {
    if (proxyHost != null && proxyPort != null && proxyHost.isNotEmpty && proxyPort.isNotEmpty) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => "PROXY $proxyHost:$proxyPort";
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    } else {
      _dio.httpClientAdapter = IOHttpClientAdapter();
    }
  }
  static void init({String? proxyHost, int? proxyPort}) {
    if (proxyHost != null && proxyPort != null) {
      setProxy(proxyHost, proxyPort.toString());
    }
  }

  static Future<Response> retryGet(String url, {
    Map<String, dynamic>? headers,
    int retryCount = 0,
    Map<String, dynamic>? customRetryConfig,
  }) async {
    int timeout = 10000;
    if (url.contains('dlsite')) {
      timeout = 10000;
    } else if (url.contains('hvdb')) {
      timeout = 10000;
    }

    final int limit = customRetryConfig?['limit'] ?? defaultRetryLimit;
    final int delay = customRetryConfig?['retryDelay'] ?? defaultRetryDelay;

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