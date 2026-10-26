import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';
import 'package:kikoenai/features/player/provider/player_cloud_file_source_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

void main() {
  test(
    'AList resolves original endpoint after global source switched; signatures survive',
    () async {
      final hits = <String>[];
      Future<HttpServer> server(String name) async {
        final result = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        result.listen((request) async {
          hits.add(name);
          await request.drain<void>();
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'code': 200,
              'data': {
                'content': [
                  {
                    'name': 'track.mp3',
                    'is_dir': false,
                    'size': 42,
                    'sign': 'keep-sign',
                  },
                ],
                'total': 1,
              },
            }),
          );
          await request.response.close();
        });
        addTearDown(() => result.close(force: true));
        return result;
      }

      final aServer = await server('A');
      final bServer = await server('B');
      final a = ServerInfo(
        id: 'a',
        baseUrl: 'http://127.0.0.1:${aServer.port}',
        label: 'A',
      );
      final b = ServerInfo(
        id: 'b',
        baseUrl: 'http://127.0.0.1:${bServer.port}',
        label: 'B',
      );
      final api = AsmrGaySiteApi(
        servers: [a, b],
        initialServer: a,
        rawBaseUrl: null,
      );
      addTearDown(api.httpClient.close);
      final track = PlaybackItem.fromFileNode(
        api.toFileNode(const FsEntry(name: 'track.mp3'), parentPath: '/album'),
      );
      await api.switchServer(b);
      final registry = SiteRegistry()
        ..registerRuntime(
          SiteRuntime.fromApi(
            info: SiteInfo(
              id: AsmrGaySiteApi.info.id,
              name: 'AList',
              version: 'test',
              servers: [a, b],
            ),
            api: api,
          ),
        );
      final container = ProviderContainer.test(
        overrides: [siteRegistryProvider.overrideWithValue(registry)],
      );
      final provider = playerCloudFileSourceProvider((
        track: track,
        legacyConnectionId: null,
      ));
      container.listen(provider, (_, __) {});
      final bound = await container.read(provider.future);
      final result = await bound.list(path: '/album', page: 1, pageSize: 50);
      expect(hits, ['A']);
      expect(api.currentServer, b);
      expect(
        result.items.single.mediaStreamUrl,
        contains('${aServer.port}/d/album/track.mp3?sign=keep-sign'),
      );
      expect(result.items.single.fileOrigin, track.fileOrigin);
    },
  );

  test(
    'built-in mirrors share identity while custom endpoints remain separate',
    () {
      final builtIns = AsmrGaySiteApi.info.servers
          .map(AsmrGaySiteApi.connectionIdForServer)
          .toSet();
      expect(builtIns.length, 1);
      const a = ServerInfo(
        id: 'same-id',
        baseUrl: 'https://a.example/drive/',
        label: 'A',
      );
      const b = ServerInfo(
        id: 'same-id',
        baseUrl: 'https://b.example/drive/',
        label: 'B',
      );
      expect(
        AsmrGaySiteApi.connectionIdForServer(a),
        isNot(AsmrGaySiteApi.connectionIdForServer(b)),
      );
    },
  );

  test(
    'WebDAV bypasses site registry and rejects a different account',
    () async {
      final container = ProviderContainer.test(
        overrides: [
          webDavConnectionControllerProvider.overrideWith(_ConnectedWebDav.new),
        ],
      );
      final connection = container.read(webDavConnectionControllerProvider);
      final track = _webDavTrack(connection.connectionId);
      final provider = playerCloudFileSourceProvider((
        track: track,
        legacyConnectionId: null,
      ));
      container.listen(provider, (_, __) {});
      final bound = await container.read(provider.future);
      expect(bound.origin.parentPath, '/root/album');
      final wrong = playerCloudFileSourceProvider((
        track: _webDavTrack('different-account'),
        legacyConnectionId: null,
      ));
      container.listen(wrong, (_, __) {});
      await expectLater(
        container.read(wrong.future),
        throwsA(isA<PlayerCloudSourceException>()),
      );
      (container.read(webDavConnectionControllerProvider.notifier)
              as _ConnectedWebDav)
          .changeAccount();
      expect(bound.validate, throwsA(isA<PlayerCloudSourceException>()));
    },
  );

  test(
    'legacy WebDAV confirmation is bound to the exact current connection',
    () async {
      final container = ProviderContainer.test(
        overrides: [
          webDavConnectionControllerProvider.overrideWith(_ConnectedWebDav.new),
        ],
      );
      final track = _webDavTrack(null);
      final request = playerCloudFileSourceProvider((
        track: track,
        legacyConnectionId: null,
      ));
      container.listen(request, (_, __) {});
      await expectLater(
        container.read(request.future),
        throwsA(
          isA<PlayerCloudSourceException>().having(
            (e) => e.canBindLegacy,
            'confirmation',
            isTrue,
          ),
        ),
      );
      final connectionId = container
          .read(webDavConnectionControllerProvider)
          .connectionId;
      final accepted = playerCloudFileSourceProvider((
        track: track,
        legacyConnectionId: connectionId,
      ));
      container.listen(accepted, (_, __) {});
      expect(
        (await container.read(accepted.future)).origin.connectionId,
        connectionId,
      );
      (container.read(webDavConnectionControllerProvider.notifier)
              as _ConnectedWebDav)
          .changeAccount();
      await expectLater(
        container.read(accepted.future),
        throwsA(
          isA<PlayerCloudSourceException>().having(
            (e) => e.canBindLegacy,
            'must reconfirm',
            isTrue,
          ),
        ),
      );
    },
  );

  test(
    'WebDAV auth resolver preserves legacy auth but cannot use another account for new tracks',
    () {
      final client = webdav.newClient(
        'https://cloud.example/dav/',
        user: 'user',
        password: 'secret',
      );
      client.auth = const webdav.BasicAuth(user: 'user', pwd: 'secret');
      addTearDown(() => client.c.close(force: true));
      Map<String, String> headers(PlaybackItem item) =>
          WebDavController.buildPlaybackHttpHeaders(
            client: client,
            baseUri: Uri.parse('https://cloud.example/dav/'),
            url: item.url,
            extras: item.toMediaItem().extras!,
            connectionId: 'connection-a',
          );
      expect(headers(_webDavTrack(null)), contains('Authorization'));
      expect(headers(_webDavTrack('connection-a')), contains('Authorization'));
      expect(headers(_webDavTrack('connection-b')), isEmpty);
    },
  );
}

PlaybackItem _webDavTrack(String? connectionId) => PlaybackItem(
  id: 'legacy',
  url: 'https://cloud.example/dav/root/album/track.mp3',
  title: 'track.mp3',
  scopeId: '/root/album',
  source: NodeSource.cloudDrive,
  siteId: webDavSiteId,
  remoteId: '/root/album/track.mp3',
  fileOrigin: connectionId == null
      ? null
      : FileOrigin(
          kind: FileOriginKind.webDav,
          connectionId: connectionId,
          filePath: '/root/album/track.mp3',
          rootPath: '/root',
        ),
);

class _ConnectedWebDav extends WebDavController {
  @override
  WebDavSessionState build() => const WebDavSessionState(
    serverUrl: 'https://cloud.example/dav/',
    username: 'user',
    rootPath: '/root',
    isConnected: true,
  );
  void changeAccount() => state = state.copyWith(username: 'another-user');
}
