import 'dart:async';

typedef MediaHttpHeadersResolver =
    Map<String, String> Function(MediaHttpHeadersRequest request);

class MediaHttpHeadersChanged {
  const MediaHttpHeadersChanged({required this.source, this.siteId});

  final String source;
  final String? siteId;

  bool matches(Map<String, dynamic>? extras) {
    if (extras?['source'] != source) return false;
    return siteId == null || extras?['siteId'] == siteId;
  }
}

class MediaHttpHeadersRequest {
  const MediaHttpHeadersRequest({required this.url, required this.extras});

  final String url;
  final Map<String, dynamic> extras;
}

class MediaHttpHeadersRegistry {
  MediaHttpHeadersRegistry();

  static final MediaHttpHeadersRegistry instance = MediaHttpHeadersRegistry();

  final List<MediaHttpHeadersResolver> _resolvers = [];
  final StreamController<MediaHttpHeadersChanged> _changes =
      StreamController<MediaHttpHeadersChanged>.broadcast();

  Stream<MediaHttpHeadersChanged> get changes => _changes.stream;

  void Function() register(MediaHttpHeadersResolver resolver) {
    _resolvers.add(resolver);
    var disposed = false;
    return () {
      if (disposed) return;
      disposed = true;
      _resolvers.remove(resolver);
    };
  }

  Map<String, String> resolve({
    required String url,
    required Map<String, dynamic> extras,
  }) {
    for (final resolver in _resolvers.reversed) {
      final headers = resolver(
        MediaHttpHeadersRequest(url: url, extras: extras),
      );
      if (headers.isNotEmpty) return Map.unmodifiable(headers);
    }
    return const {};
  }

  void notifyChanged({required String source, String? siteId}) {
    _changes.add(MediaHttpHeadersChanged(source: source, siteId: siteId));
  }
}
