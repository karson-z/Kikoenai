import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  test('private AList sign survives the complete playback conversion', () {
    const server = ServerInfo(
      id: 'private',
      baseUrl: 'https://alist.example.com',
      label: 'Private AList',
      isDefault: true,
    );
    final client = SitesHttpClient(
      config: const RequestConfig(
        baseUrl: 'https://alist.example.com',
        enableCookie: false,
      ),
    );
    addTearDown(client.close);
    final api = AsmrGaySiteApi(
      servers: const [server],
      initialServer: server,
      httpClient: client,
      rawBaseUrl: null,
    );

    final node = api.toFileNode(
      const FsEntry(name: 'private track.mp3', sign: 'signed-token'),
      parentPath: '/protected',
    );
    final playbackItem = PlaybackItem.fromFileNode(node);
    final mediaItem = playbackItem.toMediaItem();

    expect(
      mediaItem.extras!['url'],
      'https://alist.example.com/d/protected/private%20track.mp3'
      '?sign=signed-token',
    );
    expect(mediaItem.extras!['source'], NodeSource.asmrGay.name);
    expect(mediaItem.extras!['siteId'], AsmrGaySiteApi.info.id);
    expect(mediaItem.extras!['remoteId'], '/protected/private track.mp3');
  });
}
