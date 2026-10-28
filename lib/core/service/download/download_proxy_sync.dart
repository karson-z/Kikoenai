import '../proxy/system_proxy_config.dart';

/// Serializes updates because the native downloader writes host and port in
/// separate calls. A failed write is retried before the next enqueue/resume.
class DownloadProxySync {
  DownloadProxySync({
    required this.readConfig,
    required this.configure,
    this.useSystemProxy = false,
    this.hasManualProxy,
  });

  final SystemProxyConfig Function() readConfig;
  final Future<void> Function(Object proxy) configure;
  final bool useSystemProxy;
  final bool Function()? hasManualProxy;
  Future<void> _pending = Future.value();
  ProxyEndpoint? _applied;
  bool _hasApplied = false;

  Future<void> sync() {
    _pending = _pending
        .then<void>((_) {}, onError: (Object _, StackTrace __) {})
        .then((_) async {
          final followSystem =
              useSystemProxy && !(hasManualProxy?.call() ?? false);
          final endpoint = followSystem ? null : readConfig().downloadProxy;
          if (_hasApplied && endpoint == _applied) return;
          // iOS: clear any persisted explicit override, preserving URLSession's
          // default system proxy selection when no manual proxy is enabled.
          await configure(
            endpoint == null ? false : (endpoint.host, endpoint.port),
          );
          _applied = endpoint;
          _hasApplied = true;
        });
    return _pending;
  }
}
