import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  for (final firstType in [NodeType.folder, NodeType.audio]) {
    testWidgets('DL AList click keeps the selected track after $firstType', (
      tester,
    ) async {
      final player = _RecordingPlayer();
      final nodes = [
        FileNode(
          type: firstType,
          title: 'first',
          path: '/work/first',
          source: NodeSource.asmrGay,
        ),
        FileNode(
          type: NodeType.audio,
          title: 'selected.mp3',
          path: '/work/selected.mp3',
          remoteId: '/work/selected.mp3',
          siteId: AsmrGaySiteApi.info.id,
          mediaStreamUrl:
              'https://alist.example.com/d/work/selected.mp3?sign=token',
          source: NodeSource.asmrGay,
        ),
      ];
      expect(nodes.every((node) => node.hash == null), isTrue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allTasksProvider.overrideWith(_EmptyDownloads.new),
            playerControllerProvider.overrideWith(() => player),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  FileNodeBrowser(
                    currentNodes: nodes,
                    work: const Work(id: 42),
                    source: NodeSource.asmrGay,
                    sourceResolver: (node) => node.source,
                    config: const FileBrowserConfig(showDownloadBadge: true),
                    onEnterFolder: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('selected.mp3'));
      await tester.pumpAndSettle();

      expect(player.selected?.keyId, nodes.last.keyId);
      expect(player.selected?.isAudio, isTrue);
      expect(player.selected?.playablePath, nodes.last.mediaStreamUrl);
      expect(player.siblings, nodes);
      expect(player.source, NodeSource.asmrGay);
      expect(tester.takeException(), isNull);
    });
  }

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

class _EmptyDownloads extends AllTasksNotifier {
  @override
  Future<List<TaskRecord>> build() async => [];

  @override
  Future<void> refreshTasks() async {}
}

class _RecordingPlayer extends PlayerController {
  FileNode? selected;
  List<FileNode>? siblings;
  NodeSource? source;

  @override
  AppPlayerState build() => const AppPlayerState();

  @override
  Future<void> handleFileTap(
    FileNode node,
    List<FileNode> currentNodes, {
    Work? work,
    Work? Function(FileNode node)? workOf,
    NodeSource? source,
  }) async {
    selected = node;
    siblings = currentNodes;
    this.source = source;
  }
}
