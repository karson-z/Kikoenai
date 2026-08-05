import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/features/album/provider/audio_file_provider.dart';
import 'package:kikoenai/features/album/widget/album_file_section.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_option.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeMediaSiteApi extends SiteApi {
  _FakeMediaSiteApi(this.features);

  final Set<SiteFeature> features;
  final List<String> trackRequests = [];
  final List<FsSearchRequest> searchRequests = [];

  @override
  Set<SiteFeature> get supportedFeatures => features;

  @override
  Future<List<FileNode>> getWorkTracks(String workId) async {
    trackRequests.add(workId);
    return [
      FileNode(
        type: NodeType.audio,
        title: 'track.mp3',
        hash: 'track-$workId',
        mediaStreamUrl: 'https://example.test/$workId/track.mp3',
      ),
    ];
  }

  @override
  Future<FsBrowseResult> searchFileSystem(FsSearchRequest request) async {
    searchRequests.add(request);
    return const FsBrowseResult();
  }

  @override
  Future<FsBrowseResult> browseFileSystem(FsListRequest request) async {
    return const FsBrowseResult();
  }
}

class _FakeAsmrGaySiteApi extends AsmrGaySiteApi {
  _FakeAsmrGaySiteApi() : super(rawBaseUrl: 'https://media.example.test');

  final List<FsSearchRequest> searchRequests = [];
  final List<FsListRequest> browseRequests = [];

  @override
  Future<FsBrowseResult> searchFileSystem(FsSearchRequest request) async {
    searchRequests.add(request);
    return const FsBrowseResult(
      content: [FsEntry(name: 'RJ01002500', parent: '/asmr', isDir: true)],
      total: 1,
    );
  }

  @override
  Future<FsBrowseResult> browseFileSystem(FsListRequest request) async {
    browseRequests.add(request);
    return const FsBrowseResult(
      content: [FsEntry(name: 'track.mp3', size: 1024, sign: 'signed')],
      total: 1,
    );
  }
}

class _TestFileSortNotifier extends FileSortNotifier {
  @override
  FileSortOption build() => FileSortOption.defaultOption;
}

class _TestAllTasksNotifier extends AllTasksNotifier {
  @override
  Future<List<TaskRecord>> build() async => const [];

  @override
  Future<void> refreshTasks() async {}
}

SiteRuntime _runtime(String id, String name, SiteApi api) {
  return SiteRuntime.fromApi(
    info: SiteInfo(id: id, name: name, version: '1.0.0'),
    api: api,
  );
}

void main() {
  test('media runtime provider keeps only supported source shapes', () {
    final registry = SiteRegistry()
      ..registerRuntime(
        _runtime(
          'tracks.site',
          'Tracks',
          _FakeMediaSiteApi({SiteFeature.tracks}),
        ),
      )
      ..registerRuntime(
        _runtime(
          'filesystem.site',
          'Files',
          _FakeMediaSiteApi({
            SiteFeature.fileSystemSearch,
            SiteFeature.fileSystemBrowse,
          }),
        ),
      )
      ..registerRuntime(
        _runtime(
          'search-only.site',
          'Incomplete',
          _FakeMediaSiteApi({SiteFeature.fileSystemSearch}),
        ),
      );
    final container = ProviderContainer(
      overrides: [siteRegistryProvider.overrideWithValue(registry)],
    );
    addTearDown(container.dispose);

    expect(
      container
          .read(albumMediaSiteRuntimesProvider)
          .map((runtime) => runtime.siteId),
      ['tracks.site', 'filesystem.site'],
    );
  });

  testWidgets('detail switches from tracks to file-system media by site', (
    tester,
  ) async {
    final tracksApi = _FakeMediaSiteApi({SiteFeature.tracks});
    final fileSystemApi = _FakeMediaSiteApi({
      SiteFeature.fileSystemSearch,
      SiteFeature.fileSystemBrowse,
    });
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('tracks.site', 'Tracks', tracksApi))
      ..registerRuntime(
        _runtime('filesystem.site', 'File system', fileSystemApi),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          localWorkFileIndexProvider.overrideWith((ref, workId) => null),
          fileSortProvider.overrideWith(_TestFileSortNotifier.new),
          allTasksProvider.overrideWith(_TestAllTasksNotifier.new),
          explicitDarkModeProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AlbumMediaSourcesSection(
                  work: Work(
                    id: 1002500,
                    siteId: 'tracks.site',
                    remoteId: '1002500',
                  ),
                  preferredSourceId: 'tracks.site',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tracks'), findsOneWidget);
    expect(find.text('File system'), findsOneWidget);
    expect(tracksApi.trackRequests, ['1002500']);

    await tester.tap(find.text('File system'));
    await tester.pumpAndSettle();

    expect(fileSystemApi.searchRequests, hasLength(1));
    expect(fileSystemApi.searchRequests.single.keywords, 'RJ01002500');
    expect(find.text('filesystem.site 未找到 RJ01002500'), findsOneWidget);
  });

  testWidgets('local media remains a selectable source', (tester) async {
    final registry = SiteRegistry();
    final localIndex = FileNodeLibraryIndex(
      flatNodes: [
        FileNode(
          type: NodeType.audio,
          title: 'local.mp3',
          hash: 'local-track',
          path: '/media/RJ01002500/local.mp3',
          mediaStreamUrl: '/media/RJ01002500/local.mp3',
          folderPath: '/media/RJ01002500',
          rootPath: '/media/RJ01002500',
          workId: 1002500,
          source: NodeSource.localWork,
        ),
      ],
      rootPath: '/media/RJ01002500',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          localWorkFileIndexProvider.overrideWith((ref, workId) => localIndex),
          fileSortProvider.overrideWith(_TestFileSortNotifier.new),
          allTasksProvider.overrideWith(_TestAllTasksNotifier.new),
          explicitDarkModeProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AlbumMediaSourcesSection(
                  work: Work(id: 1002500),
                  preferredSourceId: albumLocalMediaSourceId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(selector.selected, {albumLocalMediaSourceId});
    expect(find.text('local.mp3'), findsOneWidget);
  });

  testWidgets('asmr.gay keeps its own FileNode URL conversion', (tester) async {
    final api = _FakeAsmrGaySiteApi();
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('asmr.gay', 'ASMR.GAY', api));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          localWorkFileIndexProvider.overrideWith((ref, workId) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AlbumMediaSourcesSection(
                  work: Work(id: 1002500, originalWorkno: 'RJ01002500'),
                  preferredSourceId: 'asmr.gay',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.searchRequests.single.keywords, 'RJ01002500');
    expect(api.browseRequests.single.path, '/asmr/RJ01002500');
    expect(find.text('track.mp3'), findsOneWidget);

    final browser = tester.widget<FileNodeBrowser>(
      find.byType(FileNodeBrowser),
    );
    final node = browser.currentNodes.single;
    expect(node.source, NodeSource.asmrGay);
    expect(node.workId, 1002500);
    expect(
      node.mediaStreamUrl,
      'https://media.example.test/asmr/RJ01002500/track.mp3?sign=signed',
    );
  });
}
