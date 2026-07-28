import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ScraperCancelledException implements Exception {
  const ScraperCancelledException([this.reason]);

  final Object? reason;

  @override
  String toString() => reason == null
      ? 'Scraper request cancelled'
      : 'Scraper request cancelled: $reason';
}

/// Cancellation shared by every HTTP request in one scrape operation.
class ScraperCancellationToken {
  final Completer<Object?> _cancelled = Completer<Object?>();
  Object? _reason;

  bool get isCancelled => _cancelled.isCompleted;
  Object? get reason => _reason;
  Future<Object?> get whenCancelled => _cancelled.future;

  void cancel([Object? reason]) {
    if (isCancelled) return;
    _reason = reason;
    _cancelled.complete(reason);
  }

  void throwIfCancelled() {
    if (isCancelled) throw ScraperCancelledException(reason);
  }

  Future<void> wait(Duration duration) async {
    throwIfCancelled();
    await Future.any<void>([
      Future<void>.delayed(duration),
      whenCancelled.then<void>((_) {}),
    ]);
    throwIfCancelled();
  }
}

/// 爬虫专用 HTTP 客户端。
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
    ScraperCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    int timeout = 10000;
    if (url.contains('dlsite') || url.contains('hvdb')) {
      timeout = 10000;
    }

    final int limit = customRetryConfig?['limit'] ?? defaultRetryLimit;
    final int delay = customRetryConfig?['retryDelay'] ?? defaultRetryDelay;

    final requestCancelToken = CancelToken();
    final timer = Timer(Duration(milliseconds: timeout), () {
      requestCancelToken.cancel('Timeout of ${timeout}ms.');
    });
    if (cancellationToken != null) {
      unawaited(
        cancellationToken.whenCancelled.then((reason) {
          if (!requestCancelToken.isCancelled) {
            requestCancelToken.cancel(ScraperCancelledException(reason));
          }
        }),
      );
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: headers),
        cancelToken: requestCancelToken,
      );
      timer.cancel();
      cancellationToken?.throwIfCancelled();
      return response;
    } catch (e) {
      timer.cancel();
      if (cancellationToken?.isCancelled ?? false) {
        throw ScraperCancelledException(cancellationToken?.reason);
      }

      bool shouldRetry = false;
      if (e is DioException) {
        // 仅在无响应（网络问题、超时等）时重试
        if (e.response == null && retryCount < limit) {
          shouldRetry = true;
        }
      }

      if (shouldRetry) {
        final retryDelay = Duration(milliseconds: delay);
        if (cancellationToken == null) {
          await Future<void>.delayed(retryDelay);
        } else {
          await cancellationToken.wait(retryDelay);
        }
        return retryGet(
          url,
          headers: headers,
          retryCount: retryCount + 1,
          customRetryConfig: customRetryConfig,
          cancellationToken: cancellationToken,
        );
      } else {
        rethrow;
      }
    }
  }
}
