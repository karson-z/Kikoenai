import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

typedef _Handler = ResponseBody Function(RequestOptions options);

class _MockAdapter implements HttpClientAdapter {
  final Map<String, _Handler> handlers = {};
  final List<RequestOptions> requests = [];

  void json(String path, Object body, {int statusCode = 200}) {
    handlers[path] = (_) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler =
        handlers[options.path] ??
        handlers.entries
            .where((entry) => options.path.endsWith(entry.key))
            .firstOrNull
            ?.value;
    return handler?.call(options) ?? ResponseBody.fromString('Not found', 404);
  }

  @override
  void close({bool force = false}) {}
}

const _server = ServerInfo(
  id: 'nas',
  baseUrl: 'https://nas.example.com/kikoeru',
  port: 8443,
  label: 'NAS',
  useProxy: false,
  isDefault: true,
);

void main() {
  late _MockAdapter adapter;
  late SitesHttpClient client;
  late KikoeruSiteApi api;

  setUp(() {
    adapter = _MockAdapter();
    client = SitesHttpClient(
      config: const RequestConfig(
        baseUrl: 'https://nas.example.com:8443/kikoeru/api',
        enableLogger: false,
        useProxy: false,
      ),
      tokenProvider: () async => 'secret-token',
    );
    client.dio.httpClientAdapter = adapter;
    api = KikoeruSiteApi(
      servers: const [_server],
      httpClient: client,
      tokenProvider: () async => 'secret-token',
    );
  });

  tearDown(() => client.close());

  test('normalizes root/API URLs and preserves configured port', () {
    expect(
      KikoeruSiteApi.apiBaseUrlFor(_server),
      'https://nas.example.com:8443/kikoeru/api',
    );
    expect(
      KikoeruSiteApi.apiBaseUrlFor(
        const ServerInfo(
          id: 'api',
          baseUrl: 'https://example.com/api/',
          label: 'API',
        ),
      ),
      'https://example.com/api',
    );
  });

  test('declares only capabilities backed by Kikoeru endpoints', () {
    expect(api.supports(SiteFeature.search), isTrue);
    expect(api.supports(SiteFeature.popular), isTrue);
    expect(api.supports(SiteFeature.tracks), isTrue);
    expect(api.supports(SiteFeature.login), isTrue);
    expect(api.supports(SiteFeature.register), isFalse);
    expect(api.supports(SiteFeature.recommend), isFalse);
    expect(api.supports(SiteFeature.playlists), isFalse);
  });

  test('parses works and supplies authenticated cover URLs', () async {
    adapter.json('/search/needle', {
      'works': [
        {'id': 123456, 'title': 'A work'},
      ],
      'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 1},
    });

    final result = await api.searchWorks(
      const SearchWorksRequest(keyword: 'needle'),
    );

    expect(result.items.single.siteId, 'kikoeru');
    expect(result.items.single.remoteId, '123456');
    final cover = Uri.parse(result.items.single.mainCoverUrl!);
    expect(cover.path, '/kikoeru/api/cover/123456');
    expect(cover.queryParameters['type'], 'main');
    expect(cover.queryParameters['token'], 'secret-token');
  });

  test('converts Kikoeru track tree into playable absolute URLs', () async {
    adapter.json('/tracks/123456', [
      {
        'type': 'folder',
        'title': 'disc 1',
        'children': [
          {
            'type': 'audio',
            'title': 'track.mp3',
            'hash': '123456/0',
            'mediaStreamUrl': '/api/media/stream/123456/0',
            'mediaDownloadUrl': '/api/media/download/123456/0',
          },
        ],
      },
    ]);

    final tracks = await api.getWorkTracks('123456');
    final audio = tracks.single.children!.single;
    final stream = Uri.parse(audio.mediaStreamUrl!);
    expect(stream.path, '/kikoeru/api/media/stream/123456/0');
    expect(stream.queryParameters['token'], 'secret-token');
    expect(audio.siteId, 'kikoeru');
    expect(audio.remoteId, '123456');
    expect(audio.source, NodeSource.asmrServer);
  });

  test('preserves Kikoeru offloaded media paths outside /api', () async {
    adapter.json('/tracks/123456', [
      {
        'type': 'audio',
        'title': 'offloaded.flac',
        'hash': '123456/0',
        'mediaStreamUrl': '/media/stream/VoiceWork/RJ123456/offloaded.flac',
      },
    ]);

    final tracks = await api.getWorkTracks('123456');
    final stream = Uri.parse(tracks.single.mediaStreamUrl!);
    expect(
      stream.path,
      '/kikoeru/media/stream/VoiceWork/RJ123456/offloaded.flac',
    );
    expect(stream.queryParameters['token'], 'secret-token');
  });

  test('builds direct authenticated stream and download URLs', () async {
    final stream = Uri.parse(
      await api.mediaStreamUrl(workId: '123456', index: 3),
    );
    final download = Uri.parse(
      await api.mediaDownloadUrl(workId: '123456', index: 3),
    );

    expect(stream.path, '/kikoeru/api/media/stream/123456/3');
    expect(download.path, '/kikoeru/api/media/download/123456/3');
    expect(stream.queryParameters['token'], 'secret-token');
    expect(download.queryParameters['token'], 'secret-token');
  });

  test('maps popular works to dl_count sorting', () async {
    adapter.json('/works', {
      'works': <Object>[],
      'pagination': {'currentPage': 2, 'pageSize': 12, 'totalCount': 0},
    });

    await api.getPopularWorks(const SearchWorksRequest(page: 2));

    final request = adapter.requests.single;
    expect(request.queryParameters['page'], 2);
    expect(request.queryParameters['order'], 'dl_count');
    expect(request.queryParameters['sort'], 'desc');
  });

  test('login creates the complete auth session expected by the app', () async {
    adapter.json('/auth/me', {'token': 'jwt-token'});

    final auth = await api.login(
      LoginParams(username: 'admin', password: 'password'),
    );

    expect(auth.isSuccess, isTrue);
    expect(auth.token, 'jwt-token');
    expect(auth.user?.name, 'admin');
    expect(auth.user?.loggedIn, isTrue);
  });

  test('category tag syntax degrades to Kikoeru keyword search', () async {
    adapter.json('/search/ASMR', {
      'works': <Object>[],
      'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 0},
    });

    await api.searchWorks(
      const SearchWorksRequest(keyword: r'%24tag%3AASMR%24'),
    );

    expect(adapter.requests.single.path, endsWith('/search/ASMR'));
  });

  test('supports forks that use a search query parameter', () async {
    adapter.json('/search/needle', const {}, statusCode: 404);
    adapter.json('/search', {
      'works': <Object>[],
      'pagination': {'currentPage': 1, 'pageSize': 12, 'totalCount': 0},
    });

    await api.searchWorks(const SearchWorksRequest(keyword: 'needle'));

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.path, endsWith('/search'));
    expect(adapter.requests.last.queryParameters['keyword'], 'needle');
  });
}
