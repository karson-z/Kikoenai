import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// 爬虫专用 HTTP 客户端（迁移自
/// `kikoenai_app/lib/core/utils/scraper/scraper_dio.dart`）。
///
/// 与 [SitesHttpClient] 区分：本客户端面向外部站点（DLSite / HVDB），
/// 不携带 ASMR 站点的 Referer / Origin / Auth 头，支持重试与代理。
class ScraperHttpClient {
  ScraperHttpClient._();

  static final Dio _dio = Dio();

  static int defaultRetryLimit = 5;
  static int defaultRetryDelay = 2000;

  /// 配置代理
  static void setProxy(String? proxyHost, String? proxyPort) {
    if (proxyHost != null &&
        proxyPort != null &&
        proxyHost.isNotEmpty &&
        proxyPort.isNotEmpty) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => 'PROXY $proxyHost:$proxyPort';
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    } else {
      _dio.httpClientAdapter = IOHttpClientAdapter();
    }
  }

  /// 初始化
  static void init({String? proxyHost, int? proxyPort}) {
    if (proxyHost != null && proxyPort != null) {
      setProxy(proxyHost, proxyPort.toString());
    }
  }

  /// 带重试的 GET 请求
  static Future<Response> retryGet(
    String url, {
    Map<String, dynamic>? headers,
    int retryCount = 0,
    Map<String, dynamic>? customRetryConfig,
  }) async {
    int timeout = 10000;
    if (url.contains('dlsite') || url.contains('hvdb')) {
      timeout = 10000;
    }

    final int limit = customRetryConfig?['limit'] ?? defaultRetryLimit;
    final int delay = customRetryConfig?['retryDelay'] ?? defaultRetryDelay;

    final cancelToken = CancelToken();
    final timer = Timer(Duration(milliseconds: timeout), () {
      cancelToken.cancel('Timeout of ${timeout}ms.');
    });

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      timer.cancel();
      return response;
    } catch (e) {
      timer.cancel();

      bool shouldRetry = false;
      if (e is DioException) {
        // 仅在无响应（网络问题、超时等）时重试
        if (e.response == null && retryCount < limit) {
          shouldRetry = true;
        }
      }

      if (shouldRetry) {
        await Future.delayed(Duration(milliseconds: delay));
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
