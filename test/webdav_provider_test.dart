import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/player/media_http_headers_registry.dart';
import 'package:kikoenai/features/cloud_drive/data/webdav_credential_store.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class _ConnectedWebDavController extends WebDavController {
  @override
  WebDavSessionState build() => const WebDavSessionState(
    serverUrl: 'https://active.example.com/dav/',
    username: 'active-user',
    rootPath: '/active',
    isConnected: true,
  );
}

class _FakeWebDavClient extends webdav.Client {
  _FakeWebDavClient(WebDavConnectionConfig config)
    : super(
        uri: config.serverUrl,
        c: webdav.WdDio(),
        auth: webdav.BasicAuth(user: config.username, pwd: config.password),
      );

  @override
  Future<List<webdav.File>> readDir(
    String path, [
    CancelToken? cancelToken,
  ]) async => const [];
}

class _FakeConnectableWebDavController extends WebDavController {
  @override
  WebDavSessionState build() => const WebDavSessionState();

  @override
  webdav.Client createClient(WebDavConnectionConfig config) =>
      _FakeWebDavClient(config);

  @override
  Future<void> persistConnectionConfig(WebDavConnectionConfig config) async {}
}

class _RestorableWebDavController extends _FakeConnectableWebDavController {
  @override
  WebDavSessionState build() => const WebDavSessionState(
    serverUrl: 'https://cloud.example.com/dav/',
    username: 'kiko',
    rootPath: '/',
  );
}

class _MemoryWebDavCredentialStore implements WebDavCredentialStore {
  _MemoryWebDavCredentialStore([this.password]);

  String? password;

  @override
  Future<String?> readPassword() async => password;

  @override
  Future<void> writePassword(String password) async {
    this.password = password;
  }

  @override
  Future<void> deletePassword() async {
    password = null;
  }
}

const _webDavPlaybackItem = PlaybackItem(
  id: 'webdav-track',
  url: 'https://cloud.example.com/dav/ASMR/track.mp3',
  title: 'track.mp3',
  source: NodeSource.cloudDrive,
  scopeId: '/ASMR',
  siteId: webDavSiteId,
  remoteId: '/ASMR/track.mp3',
);

Map<String, String> _resolvePlaybackHeaders(MediaItem item) =>
    MediaHttpHeadersRegistry.instance.resolve(
      url: item.extras!['url'] as String,
      extras: item.extras!,
    );

void main() {
  group('WebDavConnectionConfig', () {
    test('normalizes endpoint and root directory', () {
      final config = const WebDavConnectionConfig(
        serverUrl: ' https://cloud.example.com/dav ',
        username: ' kiko ',
        password: 'secret',
        rootPath: r'ASMR\Favorites/',
      ).validated();

      expect(config.serverUrl, 'https://cloud.example.com/dav/');
      expect(config.username, 'kiko');
      expect(config.rootPath, '/ASMR/Favorites');
      expect(config.password, 'secret');
    });

    test('rejects credentials embedded in the endpoint', () {
      expect(
        () => const WebDavConnectionConfig(
          serverUrl: 'https://user:secret@cloud.example.com/dav/',
          username: '',
          password: '',
          rootPath: '/',
        ).validated(),
        throwsFormatException,
      );
    });

    test('rejects parent traversal in the configured root', () {
      expect(
        () => const WebDavConnectionConfig(
          serverUrl: 'https://cloud.example.com/dav/',
          username: '',
          password: '',
          rootPath: '/../private',
        ).validated(),
        throwsFormatException,
      );
    });
  });

  test('buildFileUri encodes path without leaking credentials', () {
    final uri = WebDavController.buildFileUri(
      Uri.parse('https://cloud.example.com/remote.php/dav/files/kiko/'),
      '/ASMR/中文 音声.mp3',
    );

    expect(uri.userInfo, isEmpty);
    expect(uri.pathSegments, [
      'remote.php',
      'dav',
      'files',
      'kiko',
      'ASMR',
      '中文 音声.mp3',
    ]);
    expect(
      uri.toString(),
      contains('%E4%B8%AD%E6%96%87%20%E9%9F%B3%E5%A3%B0.mp3'),
    );
  });

  test('buildPlaybackHttpHeaders injects authorization for WebDAV media', () {
    final client = webdav.newClient(
      'https://cloud.example.com/remote.php/dav/files/kiko/',
      user: 'kiko',
      password: 'secret',
    );
    client.auth = const webdav.BasicAuth(user: 'kiko', pwd: 'secret');

    final headers = WebDavController.buildPlaybackHttpHeaders(
      client: client,
      baseUri: Uri.parse(
        'https://cloud.example.com/remote.php/dav/files/kiko/',
      ),
      url: 'https://cloud.example.com/remote.php/dav/files/kiko/ASMR/track.mp3',
      extras: const {
        'source': 'cloudDrive',
        'siteId': webDavSiteId,
        'remoteId': '/ASMR/track.mp3',
      },
    );

    expect(
      headers['Authorization'],
      'Basic ${base64Encode(utf8.encode('kiko:secret'))}',
    );
  });

  test('buildPlaybackHttpHeaders generates Digest auth for the media URI', () {
    final client = webdav.newClient(
      'https://cloud.example.com/dav/',
      user: 'kiko',
      password: 'secret',
    );
    addTearDown(() => client.c.close(force: true));
    client.auth = webdav.DigestAuth(
      user: 'kiko',
      pwd: 'secret',
      dParts: webdav.DigestParts(
        'Digest realm="private", nonce="server-nonce", '
        'qop="auth", opaque="opaque-value", algorithm="MD5"',
      ),
    );

    final headers = WebDavController.buildPlaybackHttpHeaders(
      client: client,
      baseUri: Uri.parse('https://cloud.example.com/dav/'),
      url: 'https://cloud.example.com/dav/ASMR/track.mp3?download=1',
      extras: const {'source': 'cloudDrive', 'siteId': webDavSiteId},
    );

    final authorization = headers['Authorization'];
    expect(authorization, startsWith('Digest '));
    expect(authorization, contains('username="kiko"'));
    expect(authorization, contains('nonce="server-nonce"'));
    expect(authorization, contains('uri="/dav/ASMR/track.mp3?download=1"'));
    expect(authorization, contains('qop=auth'));
  });

  test('does not forward WebDAV auth to a cross-origin redirect target', () {
    final client = webdav.newClient(
      'https://cloud.example.com/dav/',
      user: 'kiko',
      password: 'secret',
    );
    addTearDown(() => client.c.close(force: true));
    client.auth = const webdav.BasicAuth(user: 'kiko', pwd: 'secret');
    const extras = {'source': 'cloudDrive', 'siteId': webDavSiteId};

    final sourceHeaders = WebDavController.buildPlaybackHttpHeaders(
      client: client,
      baseUri: Uri.parse('https://cloud.example.com/dav/'),
      url: 'https://cloud.example.com/dav/ASMR/track.mp3',
      extras: extras,
    );
    final redirectedHeaders = WebDavController.buildPlaybackHttpHeaders(
      client: client,
      baseUri: Uri.parse('https://cloud.example.com/dav/'),
      url: 'https://cdn.example.com/ASMR/track.mp3',
      extras: extras,
    );

    expect(sourceHeaders, contains('Authorization'));
    expect(redirectedHeaders, isEmpty);
  });

  test('buildPlaybackHttpHeaders ignores non-WebDAV media urls', () {
    final client = webdav.newClient(
      'https://cloud.example.com/remote.php/dav/files/kiko/',
      user: 'kiko',
      password: 'secret',
    );
    client.auth = const webdav.BasicAuth(user: 'kiko', pwd: 'secret');

    final headers = WebDavController.buildPlaybackHttpHeaders(
      client: client,
      baseUri: Uri.parse(
        'https://cloud.example.com/remote.php/dav/files/kiko/',
      ),
      url: 'https://cdn.example.com/ASMR/track.mp3',
      extras: {
        'source': NodeSource.cloudDrive.name,
        'siteId': webDavSiteId,
        'remoteId': '/ASMR/track.mp3',
      },
    );

    expect(headers, isEmpty);
  });

  test('describeError returns an actionable authentication message', () {
    final request = RequestOptions(path: '/');
    final error = DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    expect(WebDavController.describeError(error), contains('认证失败'));
  });

  test('invalid reconnect keeps the active session state', () async {
    final container = ProviderContainer(
      overrides: [
        webDavConnectionControllerProvider.overrideWith(
          _ConnectedWebDavController.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    final connected = await container
        .read(webDavConnectionControllerProvider.notifier)
        .connect(
          const WebDavConnectionConfig(
            serverUrl: 'not-a-url',
            username: 'replacement',
            password: 'secret',
            rootPath: '/replacement',
          ),
        );
    final state = container.read(webDavConnectionControllerProvider);

    expect(connected, isFalse);
    expect(state.isConnected, isTrue);
    expect(state.serverUrl, 'https://active.example.com/dav/');
    expect(state.username, 'active-user');
    expect(state.rootPath, '/active');
    expect(state.errorMessage, isNotNull);
  });

  test(
    'cold-start automatically reconnects and rebinds restored WebDAV auth',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'kikoenai_webdav_restore_',
      );
      addTearDown(() async {
        await Hive.close();
        await tempDirectory.delete(recursive: true);
      });
      Hive.init(tempDirectory.path);
      if (!Hive.isAdapterRegistered(NodeSourceAdapter().typeId)) {
        Hive.registerAdapter(NodeSourceAdapter());
      }
      if (!Hive.isAdapterRegistered(PlaybackItemAdapter().typeId)) {
        Hive.registerAdapter(PlaybackItemAdapter());
      }
      if (!Hive.isAdapterRegistered(PlaybackSessionAdapter().typeId)) {
        Hive.registerAdapter(PlaybackSessionAdapter());
      }

      final box = await Hive.openBox<PlaybackSession>('playback_session');
      await box.put('latest', PlaybackSession.fromQueue([_webDavPlaybackItem]));
      await box.close();

      final restoredBox = await Hive.openBox<PlaybackSession>(
        'playback_session',
      );
      final restoredItem = restoredBox.get('latest')!.mediaItems.single;
      expect(restoredItem.extras!['source'], NodeSource.cloudDrive.name);
      expect(restoredItem.extras!['siteId'], webDavSiteId);
      expect(restoredItem.extras!['remoteId'], '/ASMR/track.mp3');
      expect(_resolvePlaybackHeaders(restoredItem), isEmpty);

      final credentialStore = _MemoryWebDavCredentialStore('secret');
      final container = ProviderContainer(
        overrides: [
          webDavCredentialStoreProvider.overrideWithValue(credentialStore),
          webDavConnectionControllerProvider.overrideWith(
            _RestorableWebDavController.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(webDavAutoRestoreProvider.future), isTrue);

      expect(_resolvePlaybackHeaders(restoredItem), contains('Authorization'));
      await container
          .read(webDavConnectionControllerProvider.notifier)
          .disconnect();
    },
  );

  test('disconnect unregisters auth for the current WebDAV item', () async {
    final currentItem = _webDavPlaybackItem.toMediaItem();
    final credentialStore = _MemoryWebDavCredentialStore();
    final container = ProviderContainer(
      overrides: [
        webDavCredentialStoreProvider.overrideWithValue(credentialStore),
        webDavConnectionControllerProvider.overrideWith(
          _FakeConnectableWebDavController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      webDavConnectionControllerProvider.notifier,
    );
    await controller.connect(
      const WebDavConnectionConfig(
        serverUrl: 'https://cloud.example.com/dav/',
        username: 'kiko',
        password: 'secret',
        rootPath: '/',
      ),
    );
    expect(_resolvePlaybackHeaders(currentItem), contains('Authorization'));
    expect(credentialStore.password, 'secret');

    await controller.disconnect();

    expect(_resolvePlaybackHeaders(currentItem), isEmpty);
    expect(credentialStore.password, isNull);
  });
}
