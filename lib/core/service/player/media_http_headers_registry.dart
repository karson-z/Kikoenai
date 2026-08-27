typedef MediaHttpHeadersResolver =
    Map<String, String> Function(MediaHttpHeadersRequest request);

class MediaHttpHeadersRequest {
  const MediaHttpHeadersRequest({required this.url, required this.extras});

  final String url;
  final Map<String, dynamic> extras;
}

class MediaHttpHeadersRegistry {
  MediaHttpHeadersRegistry();

  static final MediaHttpHeadersRegistry instance = MediaHttpHeadersRegistry();

  final List<MediaHttpHeadersResolver> _resolvers = [];

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
}
