import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/features/album/widget/album_file_section.dart';
import 'package:kikoenai/features/album/model/album_detail_args.dart';
import 'package:kikoenai/features/album/page/album_detail.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_aggregation_controller.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_models.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_resolvers.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_option.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeMediaSiteApi extends SiteApi {
  _FakeMediaSiteApi(this.features);

  final Set<SiteFeature> features;
  final List<String> trackRequests = [];

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
}

class _TestFileSortNotifier extends FileSortNotifier {
  @override
  FileSortOption build() => FileSortOption.defaultOption;
}

class _EmptyDlResolver implements DlMediaResolver {
  @override
  DlMediaSourceDescriptor get descriptor => const DlMediaSourceDescriptor(
    key: DlMediaSourceKey(
      kind: DlMediaSourceKind.local,
      providerId: 'test-local',
    ),
    label: '本地',
    nodeSource: NodeSource.localWork,
  );

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) async => null;
}

class _AvailableDlResolver implements DlMediaResolver {
  _AvailableDlResolver({required this.descriptor, required this.fileName});

  @override
  final DlMediaSourceDescriptor descriptor;
  final String fileName;

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) async {
    final root = '/${descriptor.key.providerId}';
    return FileNodeLibraryIndex(
      flatNodes: [
        FileNode(
          type: NodeType.audio,
          title: fileName,
          path: '$root/$fileName',
          folderPath: root,
          rootPath: root,
          mediaStreamUrl: '$root/$fileName',
          source: descriptor.nodeSource,
          workId: workId,
        ),
      ],
      rootPath: root,
      fallbackFolderSource: descriptor.nodeSource,
    );
  }
}

class _MemoryDlPreferenceRepository implements DlMediaPreferenceRepository {
  @override
  String? read(int workId) => null;

  @override
  Future<void> save(int workId, String sourceKey) async {}
}

SiteRuntime _runtime(String id, String name, SiteApi api) {
  return SiteRuntime.fromApi(
    info: SiteInfo(id: id, name: name, version: '1.0.0'),
    api: api,
  );
}

void main() {
  testWidgets('detail reads media only from the active site', (tester) async {
    final tracksApi = _FakeMediaSiteApi({SiteFeature.tracks});
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('tracks.site', 'Tracks', tracksApi));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('tracks.site'),
          fileSortProvider.overrideWith(_TestFileSortNotifier.new),
          explicitDarkModeProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [AlbumMediaSourceSection(work: Work(id: 1002500))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('track.mp3'), findsOneWidget);
    expect(tracksApi.trackRequests, ['1002500']);
  });

  testWidgets('detail rejects file-system-only active sites', (tester) async {
    final api = _FakeMediaSiteApi({
      SiteFeature.fileSystemSearch,
      SiteFeature.fileSystemBrowse,
    });
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('filesystem.site', 'File system', api));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('filesystem.site'),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [AlbumMediaSourceSection(work: Work(id: 1002500))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前站点不支持作品媒体'), findsOneWidget);
    expect(api.trackRequests, isEmpty);
  });

  testWidgets('DL detail renders scraped metadata without site actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dlMediaResolversProvider.overrideWithValue([_EmptyDlResolver()]),
          dlMediaPreferenceRepositoryProvider.overrideWithValue(
            _MemoryDlPreferenceRepository(),
          ),
          explicitDarkModeProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: AlbumDetailContainer(
            workId: 1002500,
            initialWork: Work(
              id: 1002500,
              title: 'DL metadata',
              vas: [VA(name: 'Read-only VA')],
              tags: [Tag(name: 'Read-only tag')],
            ),
            mode: AlbumDetailMode.dlLibrary,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DL metadata'), findsOneWidget);
    expect(find.text('RJ01002500'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);
    expect(find.byIcon(Icons.menu_open), findsNothing);
    expect(find.text('没有找到可用的音视频资源'), findsOneWidget);
    for (final label in ['Read-only VA', 'Read-only tag']) {
      final gesture = tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(gesture.onTap, isNull);
    }
  });

  testWidgets('DL detail switches between available media sources', (
    tester,
  ) async {
    final local = _AvailableDlResolver(
      descriptor: const DlMediaSourceDescriptor(
        key: DlMediaSourceKey(
          kind: DlMediaSourceKind.local,
          providerId: 'local',
        ),
        label: '本地',
        nodeSource: NodeSource.localWork,
      ),
      fileName: 'local.mp3',
    );
    final remote = _AvailableDlResolver(
      descriptor: const DlMediaSourceDescriptor(
        key: DlMediaSourceKey(
          kind: DlMediaSourceKind.contentSite,
          providerId: 'remote',
        ),
        label: 'Remote',
        nodeSource: NodeSource.asmrServer,
      ),
      fileName: 'remote.mp3',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dlMediaResolversProvider.overrideWithValue([local, remote]),
          dlMediaPreferenceRepositoryProvider.overrideWithValue(
            _MemoryDlPreferenceRepository(),
          ),
          fileSortProvider.overrideWith(_TestFileSortNotifier.new),
          explicitDarkModeProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: AlbumDetailContainer(
            workId: 1002501,
            initialWork: Work(id: 1002501, title: 'DL sources'),
            mode: AlbumDetailMode.dlLibrary,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.text('local.mp3'), findsOneWidget);
    await tester.tap(find.text('Remote'));
    await tester.pumpAndSettle();
    expect(find.text('remote.mp3'), findsOneWidget);
    expect(find.text('local.mp3'), findsNothing);
  });
}
